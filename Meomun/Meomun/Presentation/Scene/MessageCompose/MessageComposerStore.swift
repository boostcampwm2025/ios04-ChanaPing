//
//  MessageComposeStore.swift
//  Meomun
//
//  Created by 지연 on 1/12/26.
//

import Foundation
import Combine
import CoreLocation
import Supabase

enum EditorPolicy {
    static let maxCount = 30
}

final class MessageComposerStore: Store {
    struct State: Equatable {
        var startLocation: Coordinate?
        var startAddress: String = "위치 정보 없음"

        var message: String = ""
        var address: String = ""
        var selectedPlace: Place?
        var isPlaceSearchPresented: Bool = false

        var alert: AlertModel?
        var toastMessage: String?

        var confirmStatus: LoadingStatus = .idle

        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && confirmStatus != .loading
        }
    }

    enum Intent: Equatable {
        case onAppear
        case setMessage(String)
        case resetDraft

        case tapPlaceField
        case dismissPlaceSearch
        case selectPlace(Place)
        case clearPlace

        case tapConfirm

        case setAlert(AlertModel?)
        case setToast(String?)
    }

    enum Action {
        case setStartAddress(String)
        case updateMessage(String)

        case presentPlaceSearch(Bool)
        case updatePlace(Place)
        case clearPlace

        case setConfirmStatus(LoadingStatus)
        case presentAlert(AlertModel?)
        case presentToast(String?)
        case close(isSuccess: Bool)
    }

    @Published var state: State

    private let createMessageUseCase: CreateMessageUseCase
    private let reverseGeocodingUseCase: ReverseGeocodeUseCase

    private let onClose: (Bool) -> Void

    init(
        currentLocation: Coordinate,
        currentPlace: Place?,
        createMessage: CreateMessageUseCase,
        reverseGeocoding: ReverseGeocodeUseCase,
        onClose: @escaping (Bool) -> Void
    ) {
        self.state = State(
            startLocation: currentLocation,
            selectedPlace: currentPlace
        )
        self.createMessageUseCase = createMessage
        self.reverseGeocodingUseCase = reverseGeocoding
        self.onClose = onClose
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream<Action>(bufferingPolicy: .unbounded) { continuation in
            switch intent {
            case .onAppear:
                let coordinate = state.startLocation
                Task { [weak self] in
                    guard let self, let coordinate else {
                        continuation.finish()
                        return
                    }

                    let address = await self.fetchAddress(for: coordinate)
                    continuation.yield(.setStartAddress(address))
                    continuation.finish()
                }
                return

            case .setMessage(let message):
                continuation.yield(.updateMessage(message))

            case .resetDraft:
                continuation.yield(.updateMessage(""))
                continuation.yield(.close(isSuccess: false))

            case .tapPlaceField:
                continuation.yield(.presentPlaceSearch(true))

            case .dismissPlaceSearch:
                continuation.yield(.presentPlaceSearch(false))

            case .selectPlace(let place):
                continuation.yield(.updatePlace(place))
                continuation.yield(.presentPlaceSearch(false))

            case .clearPlace:
                continuation.yield(.clearPlace)

            case .tapConfirm:
                let normalized = state.message
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")

                let finalMessage = String(normalized.prefix(EditorPolicy.maxCount))

                if finalMessage != state.message {
                    continuation.yield(.updateMessage(finalMessage))
                }

                createMessage(continuation: continuation)
                return

            case .setAlert(let alert):
                continuation.yield(.presentAlert(alert))

            case .setToast(let message):
                continuation.yield(.presentToast(message))
            }

            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setStartAddress(let address):
            newState.startAddress = address

        case .updateMessage(let message):
            newState.message = message

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .updatePlace(let place):
            newState.selectedPlace = place

        case .clearPlace:
            newState.selectedPlace = nil

        case .setConfirmStatus(let status):
            newState.confirmStatus = status

        case .presentAlert(let alertModel):
            newState.alert = alertModel

        case .presentToast(let message):
            newState.toastMessage = message

        case .close(let isSuccess):
            onClose(isSuccess)
        }

        return newState
    }
}

extension MessageComposerStore {
    private func fetchAddress(for coordinate: Coordinate) async -> String {
        let address: String
        do {
            address = try await reverseGeocodingUseCase.execute(
                longitude: coordinate.longitude,
                latitude: coordinate.latitude
            )
            return address

        } catch {
            AppLog.error("Failed to get address from coordinates", category: .store, error: error)
            return "위치 없음"
        }
    }

    private func createMessage(continuation: AsyncStream<Action>.Continuation) {
        Task {
            continuation.yield(.setConfirmStatus(.loading))
            defer {
                continuation.finish()
            }

            do {
                guard let createMessageRequest = await makeCreateMessageRequest() else {
                    await finish(isSuccess: false, continuation)
                    return
                }

                try await createMessageUseCase.execute(createMessageRequest)
                await finish(isSuccess: true, continuation)

            } catch let error as CreateMessageError {
                AppLog.error("Failed to create message", category: .store, error: error)
                await finish(isSuccess: false, continuation)

            } catch {
                AppLog.error("Failed to create message with unknown error", category: .store, error: error)
                continuation.yield(.presentAlert(.init(
                    title: "네트워크에 연결할 수 없어요.",
                    message: "네트워크 상태를 확인하고 다시 시도해 주세요."
                )))
            }
        }
    }

    private func finish(isSuccess: Bool, _ continuation: AsyncStream<Action>.Continuation) async {
        continuation.yield(.setConfirmStatus(isSuccess ? .success : .fail))
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        continuation.yield(.close(isSuccess: isSuccess))
    }

    private func makeCreateMessageRequest() async -> CreateMessageRequest? {
        guard let startLocation = state.startLocation,
              state.startAddress != "위치 없음" else { return nil }

        return CreateMessageRequest(
            content: state.message,
            coordinate: startLocation,
            address: state.startAddress,
            place: state.selectedPlace
        )
    }

    private func mapCreateMessageErrorToAlertAction(_ error: CreateMessageError) -> Action {
        switch error {
        case .http(let code, let rawBody):
            return .presentAlert(.init(
                title: "요청 실패 (\(code))",
                message: rawBody.isEmpty ? "잠시 후 다시 시도해 주세요." : rawBody
            ))
        }
    }
}
