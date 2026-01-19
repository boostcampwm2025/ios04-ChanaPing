//
//  MessageComposeStore.swift
//  Meomun
//
//  Created by 지연 on 1/12/26.
//

import Foundation
import Combine
import Supabase

final class MessageComposerStore: Store {
    struct AlertState: Identifiable, Equatable {
        let id: UUID = UUID()
        let title: String
        let message: String
    }

    struct State: Equatable {
        var userLocation: Coordinate
        var startLocation: Coordinate
        var currentLocation: Coordinate?

        var isOutOfBoundary: Bool = false
        var didShowOutOfBoundaryAlert: Bool = false

        var message: String = ""
        var placeText: String = ""
        var isPlaceSearchPresented: Bool = false

        var alert: AlertState?
        var toastMessage: String?

        var isConfirmLoading: Bool = false
        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && isConfirmLoading == false
        }

        init(userLocation: Coordinate) {
            self.userLocation = userLocation
            self.startLocation = userLocation
            self.currentLocation = userLocation
        }
    }

    enum Intent {
        case setMessage(String)
        case updateCurrentLocation(Coordinate?)

        case tapPlaceField
        case dismissPlaceSearch
        case selectPlace(String)
        case clearPlace

        case selectSuggestedPlace(String)

        case tapConfirm
        case dismissAlert
        case dismissToast
    }

    enum Action {
        case updateMessage(String)
        case updateCurrentLocation(Coordinate?)

        case presentPlaceSearch(Bool)
        case updatePlace(String)
        case clearPlace

        case setConfirmLoading(Bool)
        case presentAlert(AlertState?)

        case showToast(String?)
        case close
    }

    @Published var state: State

    private let createMessageUseCase: CreateMessageUseCase

    private let onClose: () -> Void

    init(
        userLocation: Coordinate,
        createMessage: CreateMessageUseCase,
        onClose: @escaping () -> Void
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

            case .updateCurrentLocation(let coordinate):
                continuation.yield(.updateCurrentLocation(coordinate))

            case .tapPlaceField:
                continuation.yield(.presentPlaceSearch(true))

            case .dismissPlaceSearch:
                continuation.yield(.presentPlaceSearch(false))

            case .selectPlace(let place):
                continuation.yield(.updatePlace(place))
                continuation.yield(.presentPlaceSearch(false))

            case .clearPlace:
                continuation.yield(.clearPlace)

            case .selectSuggestedPlace(let place):
                continuation.yield(.updatePlace(place))

            case .dismissAlert:
                continuation.yield(.presentAlert(nil))

            case .dismissToast:
                continuation.yield(.showToast(nil))

            case .tapConfirm:
                if state.placeText != "" {
                    // TODO: 1차 검증) 장소 태그 존재 시, 현재 위치 기준으로 거리 검증
                }
                createMessage(continuation: continuation)
                return
            }
            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state
        switch action {
        case .updateMessage(let message):
            newState.message = message

        case .updateCurrentLocation(let coordinate):
            newState.currentLocation = coordinate

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .updatePlace(let place):
            newState.placeText = place

        case .clearPlace:
            newState.placeText = ""

        case .setConfirmLoading(let isLoading):
            newState.isConfirmLoading = isLoading

        case .presentAlert(let alertState):
            newState.alert = alertState

        case .showToast(let message):
            newState.toastMessage = message

        case .close:
            onClose()
        }
        return newState
    }
}

extension MessageComposerStore {
    private func createMessage(continuation: AsyncStream<Action>.Continuation) {
        Task {
            continuation.yield(.setConfirmLoading(true))
            defer {
                continuation.yield(.setConfirmLoading(false))
                continuation.finish()
            }

            do {
                try await createMessageUseCase.execute(makeCreateMessageRequest())

                continuation.yield(.showToast("메시지가 등록되었어요."))
                try await Task.sleep(nanoseconds: 700_000_000)
                continuation.yield(.close)

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
