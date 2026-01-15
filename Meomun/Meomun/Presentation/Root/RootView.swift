//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var store = MainTabStore()

    var body: some View {
        ZStack {
            contentView(for: store.state.selectedTab)
                .environment(\.setTabBarHidden) { hidden in
                    Task { await store.send(intent: .setTabBarHidden(hidden))}
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
        .task {
            await store.send(intent: .onAppear)
        }
    }

    @ViewBuilder
    private func contentView(for tab: MainTab) -> some View {
        switch tab {
        case .map:
            MapView(
                messageMarkerManager: .init(
                    rotationAnimator: .init(),
                    bubbleImageRenderer: .init()
                )
            )
        case .record:
            EmptyView()
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

#Preview {
    RootView()
}
