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

enum MessageComposerPolicy {
    static let maxCount = 30
    static let emptyStartAddress = "위치 정보 없음"
}

final class MessageComposerStore: Store {
    struct State: Equatable {
        var startLocation: Coordinate?
        var startAddress: String = MessageComposerPolicy.emptyStartAddress

        var message: String = ""
        var address: String = ""
        var selectedPlace: Place?
        var isPlaceSearchPresented: Bool = false

        var alert: AlertModel?
        var toastMessage: String?

        var showEmptyLocationAlert: Bool = false

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
        case confirmWithEmptyLocation

        case setAlert(AlertModel?)
        case setToast(String?)
        case retryReverseGeocoding
    }

    enum Action {
        case setStartAddress(String)
        case updateMessage(String)

        case presentPlaceSearch(Bool)
        case updatePlace(Place)
        case clearPlace

        case setShowEmptyLocationAlert(Bool)
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
                executeWithCoordinate(continuation: continuation) { [weak self] coordinate, continuation in
                    guard let self else { return }
                    let address = await self.fetchAddress(for: coordinate)
                    continuation.yield(.setStartAddress(address))
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

                let finalMessage = String(normalized.prefix(MessageComposerPolicy.maxCount))

                if finalMessage != state.message {
                    continuation.yield(.updateMessage(finalMessage))
                }

                // 케이스 1: startAddress가 "위치 정보 없음"이면 얼럿 표시
                if state.startAddress == MessageComposerPolicy.emptyStartAddress {
                    continuation.yield(.setShowEmptyLocationAlert(true))
                    break
                }

                // 케이스 2: startAddress가 정상이면 네트워크 체크 없이 진행
                createMessage(continuation: continuation, allowEmptyLocation: false)
                return

            case .setAlert(let alert):
                continuation.yield(.presentAlert(alert))

            case .setToast(let message):
                continuation.yield(.presentToast(message))

            case .confirmWithEmptyLocation:
                continuation.yield(.setShowEmptyLocationAlert(false))
                createMessage(continuation: continuation, allowEmptyLocation: true)
                return

            case .retryReverseGeocoding:
                continuation.yield(.setShowEmptyLocationAlert(false))
                executeWithCoordinate(continuation: continuation) { [weak self] coordinate, continuation in
                    guard let self else { return }
                    let address = await self.fetchAddress(for: coordinate)
                    continuation.yield(.setStartAddress(address))
                }
                return
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

        case .setShowEmptyLocationAlert(let show):
            newState.showEmptyLocationAlert = show

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
            return MessageComposerPolicy.emptyStartAddress
        }
    }

    private func executeWithCoordinate(
        continuation: AsyncStream<Action>.Continuation,
        work: @escaping @Sendable (Coordinate, AsyncStream<Action>.Continuation) async -> Void
    ) {
        let coordinate = state.startLocation
        Task {
            guard let coordinate else {
                continuation.finish()
                return
            }
            await work(coordinate, continuation)
            continuation.finish()
        }
    }

    private func createMessage(
        continuation: AsyncStream<Action>.Continuation,
        allowEmptyLocation: Bool = false
    ) {
        Task {
            continuation.yield(.setConfirmStatus(.loading))
            defer {
                continuation.finish()
            }

            do {
                AppLog.debug("createMessage 진입", category: .store)
                guard let createMessageRequest = await makeCreateMessageRequest(
                    allowEmptyLocation: allowEmptyLocation
                ) else {
                    continuation.yield(.setConfirmStatus(.fail))
                    return
                }

                AppLog.debug("\(createMessageRequest)", category: .store)
                try await createMessageUseCase.execute(createMessageRequest)
                await finish(isSuccess: true, continuation)
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

    private func makeCreateMessageRequest(allowEmptyLocation: Bool = false) async -> CreateMessageRequest? {
        AppLog.debug("makeCreateMessageRequest", category: .store)
        guard let startLocation = state.startLocation else { return nil }

        return CreateMessageRequest(
            content: state.message,
            coordinate: startLocation,
            address: state.startAddress,
            place: state.selectedPlace
        )
    }
}
