//
//  MainTabShellView.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import SwiftUI

struct MainTabShellView: View {
    @EnvironmentObject private var locationProvider: LocationProvider
    @StateObject private var mapStore = MapStore(
        getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl()),
        networkMonitor: NetworkMonitor()
    )

    let userLocation: Coordinate
    @StateObject private var store = MainTabStore()

    var body: some View {
        ZStack {
            contentView(for: store.state.selectedTab)
                .environment(\.setTabBarHidden) { hidden in
                    Task { await store.send(intent: .setTabBarHidden(hidden)) }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if !store.state.isTabBarHidden {
                FloatingTabBar(
                    selectedTab: store.state.selectedTab,
                    onSelect: { tab in
                        Task {
                            await store.send(intent: .selectTab(tab))
                        }
                    }
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .task { await store.send(intent: .onAppear) }
    }

    @ViewBuilder
    private func contentView(for tab: MainTab) -> some View {
        switch tab {
        case .map:
            MapView(
                store: mapStore,
                userLocation: userLocation,
                messageMarkerManager: MessageMarkerManager(
                    rotationAnimator: .init(),
                    bubbleImageRenderer: .init()
                )
            )

        case .record:
            TimelineListView(
                store: TimelineListStore(
                    fetchRecentMessagesUseCase: FetchRecentMessagesUseCaseImpl(
                        repository: MessageRepositoryImpl()
                    ),
                    deleteMessagesUseCase: DeleteMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl())
                )
            )

        case .myPage:
            EmptyView()
        }
    }
}

private struct SetTabBarHiddenKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var setTabBarHidden: (Bool) -> Void {
        get { self[SetTabBarHiddenKey.self] }
        set { self[SetTabBarHiddenKey.self] = newValue }
    }
}
