//
//  MapStore.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation
import Combine

final class MapStore: Store {
    enum Intent {
        case onAppear
        case onDisappear
        case updateUserLocation(Coordinate)
        case tapWriteButton
        case dismissAddMessage
        case updateMessages([Message])
    }

    enum Action {
        case setMessages([Message])
        case setUserLocation(Coordinate)
        case setShowAddMessage(Bool)
    }

    struct State {
        var messages: [Message] = []
        var userLocation: Coordinate
        var isShowingAddMessage: Bool = false
    }

    @Published var state: State

    private var messageStreamTask: Task<Void, Never>?

    init(userLocation: Coordinate) {
        self.state = State(userLocation: userLocation)
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: - api 호출 (messageStreamTask 프로퍼티 사용)
                continuation.yield(.setMessages(getDummyMessages()))
                continuation.finish()

            case .onDisappear:
                // 화면 내려갈 때 실시간 작업 정리
                messageStreamTask?.cancel()
                messageStreamTask = nil
                continuation.finish()

            case .updateUserLocation(let location):
                continuation.yield(.setUserLocation(location))
                continuation.finish()

            case .tapWriteButton:
                continuation.yield(.setShowAddMessage(true))
                continuation.finish()

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))
                continuation.finish()

            case .updateMessages(let messages):
                continuation.yield(.setMessages(messages))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setMessages(let messages):
            newState.messages = messages
        case .setUserLocation(let location):
            newState.userLocation = location
        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown
        }

        return newState
    }
}
