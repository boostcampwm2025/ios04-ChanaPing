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
        case tapWriteButton
        case dismissAddMessage
        case updateMessages([Message])
    }

    enum Action {
        case setShowAddMessage(Bool)
        case groupMessages([Message])
    }

    struct State {
        var groupedMessages: [BubbleGroupKey: [Message]] = [:]
        var isShowingAddMessage: Bool = false
    }

    @Published var state: State = .init()

    private var messageStreamTask: Task<Void, Never>?
    private let groupingUseCase = GroupMessageUseCase()

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: - api 호출 (messageStreamTask 프로퍼티 사용)
                let messages = getDummyMessages()

                continuation.yield(.groupMessages(messages))
                continuation.finish()

            case .onDisappear:
                // 화면 내려갈 때 실시간 작업 정리
                messageStreamTask?.cancel()
                messageStreamTask = nil
                continuation.finish()

            case .tapWriteButton:
                continuation.yield(.setShowAddMessage(true))
                continuation.finish()

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))
                continuation.finish()

            case .updateMessages(let messages):
                continuation.yield(.groupMessages(messages))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .groupMessages(let messages):
            let groupedMessages = groupingUseCase.groupAll(messages: messages)
            newState.groupedMessages = groupedMessages

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown
        }

        return newState
    }
}
