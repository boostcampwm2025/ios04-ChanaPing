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
        case setMessages([Message])
        case setShowAddMessage(Bool)
    }

    struct State {
        var messages: [Message] = []
        var isShowingAddMessage: Bool = false
    }

    @Published var state: State = .init()

    private var messageStreamTask: Task<Void, Never>?

    // dummy
    private let dummyMessages: [Message] = [
        Message(
            id: UUID(),
            author: User(id: UUID()),
            timestamp: Date().addingTimeInterval(-10 * 60),
            content: "오늘 좀 춥다🥲🍃",
            coordinate: .init(latitude: 37.5720, longitude: 126.9760),
            placeTag: Place(
                id: UUID(),
                name: "세종문화회관",
                coordinate: .init(latitude: 37.5720, longitude: 126.9760)
            )
        ),
        Message(
            id: UUID(),
            author: User(id: UUID()),
            timestamp: Date().addingTimeInterval(-30 * 60),
            content: "따뜻한 햇살 좋아요☀️",
            coordinate: .init(latitude: 37.5712, longitude: 126.9780),
            placeTag: Place(
                id: UUID(),
                name: "광화문광장",
                coordinate: .init(latitude: 37.5712, longitude: 126.9780)
            )
        ),
        Message(
            id: UUID(),
            author: User(id: UUID()),
            timestamp: Date().addingTimeInterval(-2 * 60 * 60),
            content: "여기 조용해서 좋아요",
            coordinate: .init(latitude: 37.5705, longitude: 126.9790),
            placeTag: nil
        ),
        Message(
            id: UUID(),
            author: User(id: UUID()),
            timestamp: Date().addingTimeInterval(-5 * 60),
            content: "바람 소리가 기분 좋아요🍃",
            coordinate: .init(latitude: 37.5730, longitude: 126.9770),
            placeTag: Place(
                id: UUID(),
                name: "경복궁 담벼락",
                coordinate: .init(latitude: 37.5730, longitude: 126.9770)
            )
        ),
        Message(
            id: UUID(),
            author: User(id: UUID()),
            timestamp: Date().addingTimeInterval(-24 * 60 * 60),
            content: "어제는 사람 많았는데 오늘은 한산하네",
            coordinate: .init(latitude: 37.5698, longitude: 126.9775),
            placeTag: nil
        )
    ]

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: - api 호출 (messageStreamTask 프로퍼티 사용)
                continuation.yield(.setMessages(dummyMessages))
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
        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown
        }

        return newState
    }
}
