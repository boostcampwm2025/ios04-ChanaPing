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

fileprivate enum BoundaryPolicy {
    static let boundaryRadiusMeters: CLLocationDistance = 200
    static let outsideBoundaryAlertTitle = "현재 머문 위치를 벗어났습니다."
    static let outsideBoundaryAlertMessage = "메세지는 계속 작성할 수 있어요."
    static let primaryButtonTitle = "새 위치로 갱신"
    static let secondaryButtonTitle = "기존 위치에 남기기"
    static let placeTagLockedMessage = "현재 위치에서는 장소 태그를 선택할 수 없어요."
}

final class MessageComposerStore: Store {
    // 위치 이탈 상태에서 사용자의 선택을 반영하기 위한 상태
    enum OutsideBoundaryDecision: Equatable {
        case none
        case refreshStartLocation   // "새 위치로 갱신"
        case keepWritingWithoutTag  // "기존 위치에 남기기"
    }

    struct State: Equatable {
        var startLocation: Coordinate
        var currentLocation: Coordinate?

        var isOutsideBoundary: Bool = false
        var didPresentOutsideBoundaryAlert: Bool = false

        var outsideBoundaryDecision: OutsideBoundaryDecision = .none
        var isPlaceTagLocked: Bool = false

        var message: String = ""
        var placeText: String = ""
        var isPlaceSearchPresented: Bool = false

        var alert: AlertModel?
        var toastMessage: String?

        var placeTagLockedHintMessage: String {
            BoundaryPolicy.placeTagLockedMessage
        }

        var isConfirmLoading: Bool = false
        var isConfirmEnabled: Bool {
            message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty == false
            && isConfirmLoading == false
            && (isOutsideBoundary == false || outsideBoundaryDecision == .keepWritingWithoutTag)
        }

        init(userLocation: Coordinate) {
            self.startLocation = userLocation
            self.currentLocation = userLocation
        }
    }

    enum Intent: Equatable {
        case setMessage(String)
        case updateCurrentLocation(Coordinate?)
        case resetDraft

        case tapPlaceField
        case dismissPlaceSearch
        case selectPlace(String)
        case clearPlace

        case tapConfirm
        case tapRefreshStartLocation
        case tapKeepWritingWithoutTag

        case setAlert(AlertModel?)
        case setToast(String?)
    }

    enum Action {
        case updateMessage(String)
        case updateCurrentLocation(Coordinate?)

        case presentPlaceSearch(Bool)
        case updatePlace(String)
        case clearPlace

        case refreshStartLocation
        case keepWritingWithoutTag

        case setConfirmLoading(Bool)
        case presentAlert(AlertModel?)
        case presentToast(String?)
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
        AppLog.debug("startLocation: \(state.startLocation)", category: .location)
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream<Action>(bufferingPolicy: .unbounded) { continuation in
            switch intent {
            case .setMessage(let message):
                continuation.yield(.updateMessage(message))

            case .updateCurrentLocation(let coordinate):
                continuation.yield(.updateCurrentLocation(coordinate))

            case .resetDraft:
                continuation.yield(.updateMessage(""))
                continuation.yield(.close)

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
                if state.isOutsideBoundary, state.outsideBoundaryDecision == .none {
                    continuation.yield(
                        .presentAlert(
                            .init(
                                title: BoundaryPolicy.outsideBoundaryAlertTitle,
                                message: BoundaryPolicy.outsideBoundaryAlertMessage,
                                buttons: [
                                    .init(
                                        title: BoundaryPolicy.primaryButtonTitle,
                                        role: .normal,
                                        action: { [weak self] in
                                            Task {
                                                await self?.send(intent: .tapRefreshStartLocation)
                                            }
                                        }
                                    ),
                                    .init(
                                        title: BoundaryPolicy.secondaryButtonTitle,
                                        role: .normal,
                                        action: { [weak self] in
                                            Task {
                                                await self?.send(intent: .tapKeepWritingWithoutTag)
                                            }
                                        }
                                    )
                                ]
                            )
                        )
                    )
                    break
                }

                createMessage(continuation: continuation)
                return

            case .tapRefreshStartLocation:
                continuation.yield(.refreshStartLocation)

            case .tapKeepWritingWithoutTag:
                continuation.yield(.keepWritingWithoutTag)

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

        case .updateCurrentLocation(let coordinate):
            newState.currentLocation = coordinate
            let wasOutOfBoundary = newState.isOutsideBoundary

            if let current = coordinate {
                let distance = distanceMeters(from: newState.startLocation, to: current)
                newState.isOutsideBoundary = distance > BoundaryPolicy.boundaryRadiusMeters
            } else {
                // 위치 정보를 받아오지 못한 경우, 기본값은 제한 범위 내부로 처리
                newState.isOutsideBoundary = false
            }

            // 제한 범위 밖으로 나가는 경우
            if wasOutOfBoundary == false,
               newState.isOutsideBoundary == true,
               newState.didPresentOutsideBoundaryAlert == false,
               newState.outsideBoundaryDecision == .none {
                newState.alert = .init(
                    title: BoundaryPolicy.outsideBoundaryAlertTitle,
                    message: BoundaryPolicy.outsideBoundaryAlertMessage,
                    buttons: [
                        .init(
                            title: BoundaryPolicy.primaryButtonTitle,
                            role: .normal,
                            action: { [weak self] in
                                Task {
                                    await self?.send(intent: .tapRefreshStartLocation)
                                }
                            }
                        ),
                        .init(
                            title: BoundaryPolicy.secondaryButtonTitle,
                            role: .normal,
                            action: { [weak self] in
                                Task {
                                    await self?.send(intent: .tapKeepWritingWithoutTag)
                                }
                            }
                        )
                    ]
                )
                newState.didPresentOutsideBoundaryAlert = true
            }

            // 제한 범위 밖에서 다시 내부로 들어오는 경우
            if wasOutOfBoundary == true,
               newState.isOutsideBoundary == false {
                newState.didPresentOutsideBoundaryAlert = false

                // 범위 내로 복귀하면 장소 태그는 자동으로 다시 활성화
                newState.isPlaceTagLocked = false
                newState.outsideBoundaryDecision = .none
            }

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .updatePlace(let place):
            newState.placeText = place

        case .clearPlace:
            newState.placeText = ""

        case .refreshStartLocation:
            // 현재 위치를 기준으로 startLocation 갱신
            if let current = newState.currentLocation {
                newState.startLocation = current
            }

            // 장소 태그는 새 기준에서 다시 선택하도록 초기화
            newState.placeText = ""

            // 선택 상태 갱신
            newState.outsideBoundaryDecision = .none
            newState.isPlaceTagLocked = false

            // 새 기준에서는 이탈 상태를 해제(다음 위치 업데이트에서 재계산됨)
            newState.isOutsideBoundary = false
            newState.didPresentOutsideBoundaryAlert = false

            // 알럿 닫기
            newState.alert = nil

        case .keepWritingWithoutTag:
            // 초기 위치는 유지하고, 장소 태그 없이 계속 작성 모드로 전환
            newState.outsideBoundaryDecision = .keepWritingWithoutTag
            newState.isPlaceTagLocked = true

            // 장소 태그가 있다면 제거
            newState.placeText = ""

            // 알럿 닫기
            newState.alert = nil

        case .setConfirmLoading(let isLoading):
            newState.isConfirmLoading = isLoading

        case .presentAlert(let alertModel):
            newState.alert = alertModel

        case .presentToast(let message):
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

                continuation.yield(.presentToast("메시지가 등록되었어요."))
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
            latitude: state.startLocation.latitude,
            longitude: state.startLocation.longitude,
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

    private func distanceMeters(from start: Coordinate, to current: Coordinate) -> CLLocationDistance {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)

        return startLocation.distance(from: currentLocation)
    }
}
