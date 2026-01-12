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
        [
            "조용함",
            "커피 맛있다",
            "분위기 좋다",
            "햇살이 좋아",
            "좌석 편하다",
            "음악이 좋다",
            "집중 잘 된다",
            "향이 좋다",
            "라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고 라떼가 최고",
            "여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다여유롭다"
        ].map { SpaceMessage(id: UUID(), text: $0) }
    }

}
