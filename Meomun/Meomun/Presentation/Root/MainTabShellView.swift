//
//  MainTabShellView.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import SwiftUI

struct MainTabShellView: View {
    @EnvironmentObject private var locationProvider: LocationProvider

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
                userLocation: userLocation,
                messageMarkerManager: MessageMarkerManager(
                    rotationAnimator: .init(),
                    bubbleImageRenderer: .init()
                )
            )

        case .record:
            EmptyView()

        case .myPage:
            SpaceView(
                store: SpaceStore(locationProvider: locationProvider),
                domeEnvironment: DomeEnvironment(
                    weather: .sunny,
                    dayPart: .daybreak
                ),
                place: Place(
                    id: PlaceID(value: ""),
                    name: "",
                    coordinate: Coordinate(
                        latitude: 0.0,
                        longitude: 0.0
                    )
                )
            )
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
