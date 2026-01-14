//
//  SpaceViewStore.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import Combine

final class SpaceViewStore: Store {

    enum Intent {
        case onAppear
        case tapWriteButton
        case dismissAddMessage
    }

    enum Action {
        case setLoading(Bool)
        case setError(String)
        case setUserLocation(Coordinate)
        case setShowAddMessage(Bool)
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
        var userLocation: Coordinate? = nil     // TODO: - 지도 > 공간 진입 시점 좌표 넘겨주고, 옵셔널 지우기
        var isShowingAddMessage: Bool = false
    }

    @Published var state: State

    private let locationProvider: LocationProvider
    private var oneShotTask: Task<Void, Never>?

    init(locationProvider: LocationProvider) {
        self.locationProvider = locationProvider
        self.state = State()
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: 서버에서 메시지 데이터 fetch
                continuation.finish()
            case .tapWriteButton:
                oneShotTask?.cancel()
                oneShotTask = nil

                continuation.yield(.setError(""))
                continuation.yield(.setLoading(true))

                oneShotTask = Task { [weak self] in
                    guard let self else { return }
                    do {
                        let coordinate = try await self.locationProvider.requestCurrentOnce()
                        AppLog.debug("Space write: got location: \(coordinate)", category: .location)
                        if Task.isCancelled { return }

                        continuation.yield(.setUserLocation(coordinate))
                        continuation.yield(.setShowAddMessage(true))
                        continuation.yield(.setLoading(false))
                        continuation.finish()
                    } catch {
                        if Task.isCancelled { return }

                        continuation.yield(.setError("현재 위치를 가져오지 못했어요."))
                        continuation.yield(.setLoading(false))
                        continuation.finish()
                    }
                }

                // 스트림 종료 시 task 정리
                continuation.onTermination = { [weak self] _ in
                    self?.oneShotTask?.cancel()
                    self?.oneShotTask = nil
                }

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setError(let message):
            newState.errorMessage = message

        case .setUserLocation(let location):
            newState.userLocation = location

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown
        }

        return newState
    }

}
