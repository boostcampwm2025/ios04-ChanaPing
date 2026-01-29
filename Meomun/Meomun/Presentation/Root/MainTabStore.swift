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
    case setting
}

final class MainTabStore: Store {

    enum Intent {
        case selectTab(MainTab)
        case setTabBarHidden(Bool)
        case onAppear
    }

    enum Action {
        case setSelectedTab(MainTab)
        case setTabBarHidden(Bool)
    }

    struct State {
        var selectedTab: MainTab = .map
        var isTabBarHidden: Bool = false
    }

    @Published var state: State = .init()

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .selectTab(let tab):
                continuation.yield(.setSelectedTab(tab))

            case .setTabBarHidden(let hidden):
                continuation.yield(.setTabBarHidden(hidden))

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

        case .setTabBarHidden(let isHidden):
            newState.isTabBarHidden = isHidden
        }

        return newState
    }
}
