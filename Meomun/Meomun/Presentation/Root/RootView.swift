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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            FloatingTabBar(
                selectedTab: store.state.selectedTab,
                onSelect: { tab in
                    Task {
                        await store.send(intent: .selectTab(tab))
                    }
                }
            )
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
            MapView()
        case .record:
            EmptyView()
        case .myPage:
            SpaceView(environment: DomeEnvironment(weather: .sunny, dayPart: .daybreak))
        }
    }
}

#Preview {
    RootView()
}
