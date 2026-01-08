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
    }

    enum Action {
        case setLoading(Bool)
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
    }

    @Published var state: State = .init()

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                // TODO: 서버에서 메시지 데이터 fetch
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }

}
