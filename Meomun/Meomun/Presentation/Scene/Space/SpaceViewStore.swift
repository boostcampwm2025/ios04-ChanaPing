//
//  SpaceViewStore.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import Combine
import Foundation

// 더미 데이터 모델
struct SpaceMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
}

final class SpaceViewStore: Store {

    enum Intent {
        case onAppear
    }

    enum Action {
        case setLoading(Bool)
        case setMessages([SpaceMessage])
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
        var messages: [SpaceMessage] = []
    }

    @Published var state: State = .init()

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: 서버에서 메시지 데이터 fetch
                continuation.yield(.setMessages(loadDummyMessages()))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setMessages(let messages):
            newState.messages = messages
        }

        return newState
    }

    private func loadDummyMessages() -> [SpaceMessage] {
        let now = Date()

        // 최근(20분 이내) + 일반(20분 이상) 메시지가 섞이도록 구성
        let samples: [(text: String, minutesAgo: Int)] = [
            ("조용함", 2),
            ("커피 맛있다", 7),
            ("분위기 좋다", 12),
            ("햇살이 좋아", 19),

            ("좌석 편하다", 25),
            ("음악이 좋다", 40),
            ("집중 잘 된다", 65),
            ("향이 좋다", 120),

            ("라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고", 5),
            ("여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다", 90)
        ]

        return samples.map { sample in
            SpaceMessage(
                id: UUID(),
                text: sample.text,
                createdAt: Calendar.current.date(byAdding: .minute, value: -sample.minutesAgo, to: now) ?? now
            )
        }
    }

}
