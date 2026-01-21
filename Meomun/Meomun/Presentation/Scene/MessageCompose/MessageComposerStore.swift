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
    enum ConfirmStatus: Equatable {
        case idle
        case sending
        case success
        case fail
    }

    struct State: Equatable {
        var startLocation: Coordinate?  // TODO: 생성자 주입 고려

        var message: String = ""
        var selectedPlace: Place?
        var isPlaceSearchPresented: Bool = false

        var alert: AlertModel?
        var toastMessage: String?

        var confirmStatus: ConfirmStatus = .idle

        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && confirmStatus != .sending
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
        case onDisappear
    }

    enum Action {
        case setInitLocation(Coordinate?)
        case updateMessage(String)

        case presentPlaceSearch(Bool)
        case updatePlace(Place)
        case clearPlace

        case setConfirmStatus(ConfirmStatus)
        case presentAlert(AlertModel?)
        case presentToast(String?)
        case close(isSuccess: Bool)
    }

    @Published var state: State

    private let createMessageUseCase: CreateMessageUseCase
    let locationProvider: LocationProvider

    private let onClose: (Bool) -> Void

    init(
        locationProvider: LocationProvider,
        createMessage: CreateMessageUseCase,
        onClose: @escaping (Bool) -> Void
    ) {
        self.state = State()
        self.locationProvider = locationProvider
        self.createMessageUseCase = createMessage
        self.onClose = onClose
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream<Action>(bufferingPolicy: .unbounded) { continuation in
            switch intent {
            case .onAppear:
                locationProvider.startContinuous()
                continuation.yield(.setInitLocation(locationProvider.current))

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

            case .onDisappear:
                locationProvider.stopContinuous()
            }

            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setInitLocation(let coordinate):
            newState.startLocation = coordinate

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
    private func createMessage(continuation: AsyncStream<Action>.Continuation) {
        Task {
            continuation.yield(.setConfirmStatus(.sending))
            defer {
                continuation.finish()
            }

            do {
                guard let createMessageRequest = makeCreateMessageRequest() else { return }
                try await createMessageUseCase.execute(createMessageRequest)
                continuation.yield(.setConfirmStatus(.success))
                try await Task.sleep(nanoseconds: 1_000_000_000)
                locationProvider.stopContinuous()
                continuation.yield(.close(isSuccess: true))
            } catch let error as CreateMessageError {
                continuation.yield(.setConfirmStatus(.fail))
                continuation.yield(mapCreateMessageErrorToAlertAction(error))
            } catch {
                continuation.yield(.setConfirmStatus(.fail))
                continuation.yield(.presentAlert(.init(
                    title: "네트워크에 연결할 수 없어요.",
                    message: "네트워크 상태를 확인하고 다시 시도해 주세요."
                )))
            }
        }
    }

    private func makeCreateMessageRequest() -> CreateMessageRequest? {
        guard let startLocation = state.startLocation else { return nil }

        return CreateMessageRequest(
            content: state.message,
            coordinate: startLocation,
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
