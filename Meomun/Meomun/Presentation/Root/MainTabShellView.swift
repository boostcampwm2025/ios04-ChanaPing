//
//  MainTabShellView.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import SwiftUI

fileprivate enum Constants {
    static let mapTitle = "머문"
    static let recordTitle = "머물렀던 순간들"
    static let settingTitle = "설정"
}

struct MainTabShellView: View {
    @StateObject private var mapStore = MapStore(
        getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl()),
        networkMonitor: NetworkMonitor()
    )

    @StateObject private var store = MainTabStore()

    var body: some View {
        ZStack {
            contentView(for: store.state.selectedTab)
                .environment(\.setTabBarHidden) { hidden in
                    Task { await store.send(intent: .setTabBarHidden(hidden)) }
                }
        }
        .safeAreaInset(edge: .top) {
            if !store.state.isTabBarHidden {
                MMFloatingNavigationBar(config: navBarConfig)
                    .padding(.top, 12)
                    .transition(.opacity)
                    .zIndex(99)
                    .animation(.easeInOut(duration: 0.25), value: store.state.selectedTab)
                    .animation(.easeInOut(duration: 0.25), value: store.state.isRecordEditing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if !store.state.isTabBarHidden {
                MMFloatingTabBar(
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
                    deleteMessagesUseCase: DeleteMessagesUseCaseImpl(
                        messageRepository: MessageRepositoryImpl()
                    )
                ),
                isEditing: store.state.isRecordEditing,
                onEditingChanged: { isEditing in
                    Task { await store.send(intent: .setRecordEditing(isEditing)) }
                }
            )

        case .setting:
            NavigationStack {
                SettingView(
                    store: SettingStore(
                        appSettingsOpener: AppSettingsOpener()
                    )
                )
            }
        }
    }

    private var navBarConfig: MMFloatingNavBarConfiguration {
        switch store.state.selectedTab {
        case .map:
            return MMFloatingNavBarConfiguration(
                title: Constants.mapTitle,
                rightItem: .search(action: {
                    Task { await mapStore.send(intent: .tapSearch) }
                })
            )

        case .record:
            return MMFloatingNavBarConfiguration(
                title: Constants.recordTitle,
                rightItem: .edit(isEditing: store.state.isRecordEditing, action: {
                    Task { await store.send(intent: .toggleRecordEditing) }
                })
            )

        case .setting:
            return MMFloatingNavBarConfiguration(
                title: Constants.settingTitle,
                rightItem: .none
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
