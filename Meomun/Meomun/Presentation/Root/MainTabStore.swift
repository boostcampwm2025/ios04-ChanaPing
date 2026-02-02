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

        case toggleRecordEditing
        case setRecordEditing(Bool)
    }

    enum Action {
        case setSelectedTab(MainTab)
        case setTabBarHidden(Bool)
        case setRecordEditing(Bool)
    }

    struct State {
        var selectedTab: MainTab = .map
        var isTabBarHidden: Bool = false
        var isRecordEditing: Bool = false
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

            case .toggleRecordEditing:
                guard state.selectedTab == .record else { return }
                continuation.yield(.setRecordEditing(!state.isRecordEditing))

            case .setRecordEditing(let isEditing):
                guard state.selectedTab == .record else { return }
                continuation.yield(.setRecordEditing(isEditing))
            }

            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setSelectedTab(let tab):
            newState.selectedTab = tab
            newState.isRecordEditing = false

        case .setTabBarHidden(let isHidden):
            newState.isTabBarHidden = isHidden

        case .setRecordEditing(let isEditing):
            newState.isRecordEditing = isEditing
        }

        return newState
    }
}
