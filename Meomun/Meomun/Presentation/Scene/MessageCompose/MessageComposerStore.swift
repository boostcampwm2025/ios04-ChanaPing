//
//  MessageComposeStore.swift
//  Meomun
//
//  Created by 지연 on 1/12/26.
//

import Foundation
import Combine

final class MessageComposerStore: Store {
    struct AlertState: Identifiable, Equatable {
        let id: UUID = UUID()
        let title: String
        let message: String
    }

    struct State: Equatable {
        var message: String = ""
        var placeText: String = ""
        var isPlaceSearchPresented: Bool = false

        var suggestPlaces: [String] = [
            "스타벅스 파주가람점", "ONUTE", "콰이어트라이트", "메가MGC커피 파주별하람마을점"
        ]
        var isConfirmLoading: Bool = false
        var alert: AlertState?

        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && isConfirmLoading == false
        }
    }

    enum Intent {
        case setMessage(String)

        case tapPlaceField
        case dismissPlaceSearch
        case selectPlace(String)
        case clearPlace

        case selectSuggestedPlace(String)

        case tapConfirm
        case dismissAlert
    }

    enum Action {
        case updateMessage(String)

        case presentPlaceSearch(Bool)
        case updatePlace(String)
        case clearPlace

        case setConfirmLoading(Bool)
        case presentAlert(AlertState?)

        case close
    }

    @Published var state: State = .init()

    private let moderateMessage: TextModerationUseCase

    init(
        moderateMessage: TextModerationUseCase
    ) {
        self.moderateMessage = moderateMessage
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .setMessage(let message):
                continuation.yield(.updateMessage(message))

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

            case .tapConfirm:
                if state.placeText != "" {
                    // TODO: 1차 검증) 장소 태그 존재 시, 현재 위치 기준으로 거리 검증
                }

                // 2차 검증) 텍스트 검증 API 호출
                Task {
                    continuation.yield(.setConfirmLoading(true))
                    defer {
                        continuation.yield(.setConfirmLoading(false))
                        continuation.finish()
                    }

                    let trimmedMessage = state.message.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmedMessage.isEmpty == false else {
                        continuation.yield(
                            .presentAlert(
                                .init(
                                    title: "메시지를 입력해주세요.",
                                    message: "내용이 비어있으면 전송할 수 없어요."
                                )
                            )
                        )
                        return
                    }

                    do {
                        let response = try await moderateMessage.execute(text: trimmedMessage)

                        switch response.decision {
                        case .ALLOW:
                            // TODO: 메시지 생성 API 호출
                            continuation.yield(.close)

                        case .REVIEW, .BLOCK:
                            continuation.yield(
                                .presentAlert(
                                    .init(
                                        title: "메시지를 남길 수 없어요.",
                                        message: response.reason
                                    )
                                )
                            )

                        case .UNKNOWN:
                            continuation.yield(
                                .presentAlert(
                                    .init(
                                        title: "검증 결과를 확인할 수 없어요.",
                                        message: "잠시 후 다시 시도해 주세요."
                                    )
                                )
                            )
                        }
                    } catch {
                        continuation.yield(
                            .presentAlert(
                                .init(
                                    title: "네트워크에 연결할 수 없어요.",
                                    message: "네트워크 상태를 확인하고 다시 시도해 주세요.")
                            )
                        )
                    }
                }
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

        case .close:
            break
        }
        return newState
    }
}
