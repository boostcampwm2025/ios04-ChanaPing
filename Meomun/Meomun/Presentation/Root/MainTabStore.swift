//
//  MainTabStore.swift
//  Meomun
//
//  Created by 지연 on 1/6/26.
//

import Combine

enum MainTab: Hashable {
    case map
    case record
    case myPage
}

final class MainTabStore: Store {

    enum Intent {
        case selectTab(MainTab)
        case onAppear
    }

    enum Action {
        case setSelectedTab(MainTab)
    }

    struct State {
        var selectedTab: MainTab = .map
    }

    @Published var state: State = .init()

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .selectTab(let tab):
                continuation.yield(.setSelectedTab(tab))

            case .onAppear:
                break
            }
            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setSelectedTab(let tab):
            newState.selectedTab = tab
        }

        return newState
    }
}
