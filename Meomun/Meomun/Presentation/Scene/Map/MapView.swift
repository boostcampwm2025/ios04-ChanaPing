//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI
import TipKit

fileprivate enum Constants {
    static let navigationTitle = "머문"
    static let locationToastMessage = "위치를 불러오지 못했어요. 잠시 후에 다시 시도해주세요."

    static let placeSearchTitle = "장소로 이동"
    static let placeSearchPlaceholder = "어디로 이동할까요?"
}

struct MapView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden
    @Environment(\.setNavBarHidden) private var setNavBarHidden
    @Environment(\.setSplashReady) private var setSplashReady
    @Environment(\.isSplashVisible) private var isSplashVisible

    @State private var navigationPath = NavigationPath()

    @ObservedObject private var store: MapStore
    @EnvironmentObject private var locationProvider: LocationProvider

    private let messageMarkerManager: MessageMarkerManager

    init(
        store: MapStore,
        messageMarkerManager: MessageMarkerManager
    ) {
        self.store = store
        self.messageMarkerManager = messageMarkerManager
    }

    private func send(_ intent: MapStore.Intent) {
        Task { await store.send(intent: intent) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                mapViewWrapper
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    if !isSplashVisible && !store.state.hasAnyMessage {
                        Color.clear
                            .frame(width: 50, height: 1)
                            .padding(.trailing, 120)
                            .padding(.bottom, MMLayout.tabBarBottomOffset + 90)
                            .popoverTip(MapPlaceConceptTip())
                    }

                    writeButton
                        .padding(.bottom, MMLayout.tabBarBottomOffset)
                }
            }
            .overlay(alignment: .topLeading) {
                tiltToggleButton
                    .padding(.top, MMLayout.belowNavigationToolbarOffset + 20)
                    .padding(.leading, 30)
            }
            .overlay(alignment: .bottom) {
                if !store.state.carouselItems.isEmpty {
                    PlaceCarousel(
                        items: store.state.carouselItems,
                        onTapped: { place in
                            send(.tapCarouselPlace(place))
                        }
                    )
                    .padding(.bottom, MMLayout.aboveTabBarOffset)
                }
            }
            .overlay {
                if !store.state.isNetworkConnected {
                    MMAlertView(type: .network) {
                        send(.tapNetworkRefresh)
                    }
                    .ignoresSafeArea()
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        send(.dismissPlaceCarousel)
                    }
            )
            .fullScreenCover(isPresented: isSpacePresentedBinding) {
                if let place = store.state.selectedPlaceForSpace {
                    spaceView(place: place)
                        .onAppear {
                            setTabBarHidden(true)
                            setNavBarHidden(true)
                        }
                        .onDisappear {
                            setTabBarHidden(false)
                            setNavBarHidden(false)
                        }
                }
            }
            .navigationDestination(for: MapDestination.self) { destination in
                switch destination {
                case .messageComposer(let location, let place):
                    messageComposerView(location: location, place: place) {
                        navigationPath.removeLast()
                    }
                    .onAppear {
                        setTabBarHidden(true)
                        setNavBarHidden(true)
                    }
                }
            }
            .task {
                let initial = locationProvider.current ?? .seoulCity
                send(.onAppear(initial))
                send(.userLocationReady(initial))
            }
            .onChange(of: locationProvider.current ?? .seoulCity) { _, newValue in
                send(.userLocationReady(newValue))
            }
            .onAppear {
                setTabBarHidden(false)
                setNavBarHidden(false)
                locationProvider.startContinuous()
                MapPlaceConceptTip.isReady = true
            }
            .onDisappear {
                send(.onDisappear)
                locationProvider.stopContinuous()
            }
            .fullScreenCover(isPresented: isPlaceSearchPresentedBinding) {
                placeSearchOverlay
                    .presentationBackground(.clear)
            }
            .transaction { $0.disablesAnimations = true }
            .sheet(isPresented: isTimelineListPresentedBinding) {
                timeLineListView
                    .background(Color.mmBackground)
                    .presentationDetents(.init(arrayLiteral: .medium, .large))
                    .presentationDragIndicator(.visible)
            }
        }
        .mmToast(toastBinding, bottomPadding: 100)
    }
}

// MARK: - SubViews

private extension MapView {
    var mapViewWrapper: some View {
        MapViewWrapper(
            userLocation: locationProvider.current ?? .seoulCity,
            isFollowingUser: store.state.isFollowingUser,
            isTiltOn: store.state.isTiltOn,
            markerManager: messageMarkerManager,
            messages: store.state.messages,
            cameraMoveTarget: store.state.cameraMoveTarget,
            onCameraMoveConsumed: {
                send(.cameraMoveConsumed)
            },
            onTapPlace: { messages in
                send(.tapPlaceMarker(messages))
            },
            onTapNoPlace: { messages in
                send(.tapNoPlaceMarker(messages))
            },
            onUserGesture: {
                send(.userDidInteractMap)
            },
            onFollowRequested: {
                send(.followUserRequested)
            },
            onCameraIdle: { coordinate, bounds, snapshot in
                send(.cameraDidIdle(coordinate, bounds, snapshot))
            },
            onCameraChangedByLocation: { coordinate, bounds, snapshot in
                send(.cameraChangedByLocation(coordinate, bounds, snapshot))
            },
            onFirstMapIdle: {
                setSplashReady()
            }
        )
    }

    var writeButton: some View {
        WriteButton {
            if let current = locationProvider.current {
                navigationPath.append(
                    MapDestination.messageComposer(
                        location: current,
                        place: nil
                    )
                )
            } else {
                send(.setToast(Constants.locationToastMessage))
            }
        }
    }

    var tiltToggleButton: some View {
        Button {
            send(.tapTiltToggle)
        } label: {
            let isTiltOn = store.state.isTiltOn
            HStack(spacing: 6) {
                Image(systemName: isTiltOn ? "graph.3d" : "graph.2d")
                Text(isTiltOn ? "3D" : "2D")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.mmWriteButton)
            .frame(width: 75, height: 38)
            .background(Color.mmFloatingBackground)
            .clipShape(Capsule())
        }
        .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation Destination

private extension MapView {
    private func messageComposerView(
        location: Coordinate,
        place: Place?,
        onClose: @escaping () -> Void
    ) -> some View {
        let factory: MessageComposerStoreFactory = DIContainer.resolveOrDie()

        return MessageComposerView(
            store: factory.make(
                currentLocation: location,
                currentPlace: place,
                onClose: { isSuccess in
                    if isSuccess {
                        send(.refreshVisibleMessages)
                    }
                    onClose()
                }
            )
        )
    }

    private func spaceView(place: Place) -> some View {
        let factory: SpaceStoreFactory = DIContainer.resolveOrDie()

        return SpaceView(
            store: factory.make(place: place)
        )
        .onDisappear {
            send(.refreshVisibleMessages)
        }
    }
}

// MARK: - Sheet & Overlay

private extension MapView {
    @ViewBuilder
    var placeSearchOverlay: some View {
        if let current = locationProvider.current {
            let factory: PlaceSearchStoreFactory = DIContainer.resolveOrDie()
            PlaceSearchOverlayView(
                store: factory.make(
                    userLocation: current,
                    onSelect: { place in
                        send(.selectPlace(place))
                    },
                    onDismiss: {
                        send(.dismissPlaceSearch)
                    }
                ),
                title: Constants.placeSearchTitle,
                placeholder: Constants.placeSearchPlaceholder
            )
        } else {
            Color.clear
                .onAppear {
                    send(.setToast(Constants.locationToastMessage))
                    send(.dismissPlaceSearch)
                }
        }
    }

    var isPlaceSearchPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.isPlaceSearchPresented },
            set: { isPresented in
                if !isPresented {
                    send(.dismissPlaceSearch)
                }
            }
        )
    }

    var isSpacePresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.selectedPlaceForSpace != nil },
            set: { isPresented in
                if !isPresented { send(.dismissSpace) }
            }
        )
    }

    var timeLineListView: some View {
        let factory: TimelineListStoreFactory = DIContainer.resolveOrDie()

        return TimelineListView(
            store: factory.make(
                initialMessages: store.state.selectedNoPlaceMessages,
                onDeletedMessages: { _ in
                    send(.refreshVisibleMessages)
                }
            ),
            isEditing: false,
            configuration: .bottomSheet,
            onBecameEmpty: {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1000))
                    send(.dismissTimelineView)
                }
            }
        )
    }

    var isTimelineListPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.selectedNoPlaceMessages.isEmpty == false },
            set: { isPresented in
                if !isPresented {
                    send(.dismissTimelineView)
                }
            }
        )
    }

    var toastBinding: Binding<String?> {
        Binding(
            get: { store.state.toastMessage },
            set: { message in
                send(.setToast(message))
            }
        )
    }
}
