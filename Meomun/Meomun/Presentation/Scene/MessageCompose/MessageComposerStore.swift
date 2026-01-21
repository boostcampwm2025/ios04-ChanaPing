//
//  MessageComposeStore.swift
//  Meomun
//
//  Created by 지연 on 1/12/26.
//

import Foundation
import Combine
import Supabase

enum EditorPolicy {
    static let maxCount = 30
}

final class MessageComposerStore: Store {
    enum ConfirmStatus: Equatable {
        case idle
        case sending
        case success
    }

    struct State: Equatable {
        var userLocation: Coordinate
        var message: String = ""
        var placeText: String = ""
        var isPlaceSearchPresented: Bool = false

        var alert: AlertModel?
        var toastMessage: String?

//        var isConfirmLoading: Bool = false
        var confirmStatus: ConfirmStatus = .idle
        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && confirmStatus != .sending
        }
    }

    enum Intent {
        case setMessage(String)
        case resetDraft

        case tapPlaceField
        case dismissPlaceSearch
        case selectPlace(String)
        case clearPlace

        case tapConfirm
        case setAlert(AlertModel?)
        case setToast(String?)
    }

    enum Action {
        case updateMessage(String)

        case presentPlaceSearch(Bool)
        case updatePlace(String)
        case clearPlace

        case setConfirmStatus(ConfirmStatus)
        case presentAlert(AlertModel?)
        case presentToast(String?)
        case close(isSuccess: Bool)
    }

    @Published var state: State

    private let createMessageUseCase: CreateMessageUseCase

    private let onClose: (Bool) -> Void

    init(
        userLocation: Coordinate,
        createMessage: CreateMessageUseCase,
        onClose: @escaping (Bool) -> Void
    ) {
        self.state = State(userLocation: userLocation)
        self.createMessageUseCase = createMessage
        self.onClose = onClose
        AppLog.debug("userLocation: \(userLocation)", category: .location)
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
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
        case .updateMessage(let message):
            newState.message = message

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .updatePlace(let place):
            newState.placeText = place

        case .clearPlace:
            newState.placeText = ""

        case .setConfirmStatus(let status):
            newState.confirmStatus = status

        case .presentAlert(let alertState):
            newState.alert = alertState

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
                try await createMessageUseCase.execute(makeCreateMessageRequest())
                continuation.yield(.setConfirmStatus(.success))
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continuation.yield(.close(isSuccess: true))

            } catch let error as CreateMessageError {
                continuation.yield(mapCreateMessageErrorToAlertAction(error))

            } catch {
                continuation.yield(.presentAlert(.init(
                    title: "네트워크에 연결할 수 없어요.",
                    message: "네트워크 상태를 확인하고 다시 시도해 주세요."
                )))
            }
        }
    }

    private func makeCreateMessageRequest() -> CreateMessageRequestDTO {
        CreateMessageRequestDTO(
            content: state.message,
            latitude: state.userLocation.latitude,
            longitude: state.userLocation.longitude,
            place: nil
        )
    }

    private func mapCreateMessageErrorToAlertAction(_ error: CreateMessageError) -> Action {
        switch error {
        case .unauthorized:
            return .presentAlert(.init(
                title: "인증이 필요해요.",
                message: "익명 로그인(세션)이 없어서 메시지를 보낼 수 없어요."
            ))

        case .blocked:
            return .presentAlert(.init(
                title: "메시지를 등록할 수 없어요.",
                message: "내용이 정책에 의해 거부되었어요."
            ))

        case .unknown:
            return .presentAlert(.init(
                title: "메시지를 등록할 수 없어요.",
                message: "정책 판단을 확정할 수 없어 등록할 수 없어요."
            ))

        case .http(let code, let rawBody):
            return .presentAlert(.init(
                title: "요청 실패 (\(code))",
                message: rawBody.isEmpty ? "잠시 후 다시 시도해 주세요." : rawBody
            ))
        }
    }

}
