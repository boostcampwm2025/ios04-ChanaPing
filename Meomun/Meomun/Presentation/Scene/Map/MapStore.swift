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
    private let dummyMessages: [Message] = {
        // ───────────── 세종문화회관 (회전 그룹) ─────────────
        let place1 = Place(
            id: UUID(),
            name: "세종문화회관",
            coordinate: .init(
                latitude: 37.5720,
                longitude: 126.9760
            )
        )

        let group1 = [
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-3 * 60),
                content: "따뜻한 바람 지나가요🍃",
                coordinate: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-12 * 60),
                content: "공연 리허설 소리 들린다🎻",
                coordinate: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            )
        ]

        // ───────────── 광화문광장 (회전 그룹) ─────────────

        let place2 = Place(
            id: UUID(),
            name: "광화문광장",
            coordinate: .init(
                latitude: 37.5712,
                longitude: 126.9780
            )
        )

        let group2 = [
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-8 * 60),
                content: "햇살이 광장 위에 내려앉았어요☀️",
                coordinate: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-50 * 60),
                content: "차분한 아침 분위기 좋다",
                coordinate: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            )
        ]

        // ───────────── 경복궁 담벼락 (회전 그룹) ─────────────
        let place3 = Place(
            id: UUID(),
            name: "경복궁 담벼락",
            coordinate: .init(
                latitude: 37.5730,
                longitude: 126.9770
            )
        )

        let group3 = [
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-6 * 60),
                content: "벽에 스치는 바람 소리가 좋다🍃",
                coordinate: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-2 * 60 * 60),
                content: "발자국 소리가 멀리 울려요",
                coordinate: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            )
        ]

        // ───────────── 단일 버블 (Static) ─────────────
        let statics = [
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-40 * 60),
                content: "벤치에 앉아 잠깐 쉬어요",
                coordinate: .init(latitude: 37.5698, longitude: 126.9775),
                placeTag: nil
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-1 * 60 * 60),
                content: "따뜻한 커피 향이 지나간다☕️",
                coordinate: .init(latitude: 37.5704, longitude: 126.9766),
                placeTag: nil
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-3 * 60 * 60),
                content: "멀리서 버스 브레이크 소리🚍",
                coordinate: .init(latitude: 37.5718, longitude: 126.9792),
                placeTag: nil
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-20 * 60),
                content: "바닥에 그림자가 길게 늘어져요🌒",
                coordinate: .init(latitude: 37.5728, longitude: 126.9756),
                placeTag: nil
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-15 * 60),
                content: "누군가 웃는 소리 지나갔다🙂",
                coordinate: .init(latitude: 37.5709, longitude: 126.9786),
                placeTag: nil
            ),
            Message(
                id: UUID(),
                author: User(id: UUID()),
                timestamp: Date().addingTimeInterval(-10 * 60 * 60),
                content: "새벽 공기가 차갑고 맑다🌙",
                coordinate: .init(latitude: 37.5692, longitude: 126.9798),
                placeTag: nil
            )
        ]

        return group1 + group2 + group3 + statics
    }()

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
