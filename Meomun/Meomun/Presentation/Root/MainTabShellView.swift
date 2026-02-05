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
        getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(
            messageRepository: MessageRepositoryImpl()
        ),
        hasAnyMessageUseCase: HasAnyMessageUseCaseImpl(
            messageRepository: MessageRepositoryImpl()
        ),
        networkMonitor: NetworkMonitor()
    )

    @StateObject private var store = MainTabStore()

    var body: some View {
        ZStack {
            contentView(for: store.state.selectedTab)
                .environment(\.setTabBarHidden) { hidden in
                    Task { await store.send(intent: .setTabBarHidden(hidden)) }
                }
                .environment(\.setNavBarHidden) { hidden in
                    Task { await store.send(intent: .setNavBarHidden(hidden)) }
                }
        }
        .safeAreaInset(edge: .top) {
            if !store.state.isNavBarHidden {
                MMFloatingNavigationBar(config: navBarConfig)
                    .padding(.top, 12)
                    .transition(.opacity)
                    .zIndex(99)
                    .background(store.state.selectedTab == .record ? Color.mmBackground : Color.clear)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.state.isTabBarHidden {
                ZStack(alignment: .bottom) {
                    Color.clear
                        .frame(height: 96)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)

                    MMFloatingTabBar(
                        selectedTab: store.state.selectedTab,
                        onSelect: { tab in
                            Task {
                                await store.send(intent: .selectTab(tab))
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        appSettingsOpener: AppSettingsOpener(),
                        resetMessagesUseCase: ResetMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl())
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
