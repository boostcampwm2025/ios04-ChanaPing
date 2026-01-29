//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "머문"
    static let locationToastMessage = "위치를 불러오지 못했어요. 잠시 후에 다시 시도해주세요."

    static let placeSearchTitle = "장소로 이동"
    static let placeSearchPlaceholder = "어디로 이동할까요?"
}

struct MapView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden

    @State private var navigationPath = NavigationPath()
    @State private var didApplyResolvedUserLocation = false

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

                VStack {
                    floatingNavigationBar
                    Spacer()
                }
                .padding(.top, 12)
            }
            .overlay(alignment: .bottomTrailing) {
                writeButton
                    .padding(.bottom, 96)
            }
            .overlay(alignment: .bottom) {
                if !store.state.carouselItems.isEmpty {
                    PlaceCarousel(
                        items: store.state.carouselItems,
                        onTapped: { place in
                            send(.dismissPlaceCarousel)
                            navigationPath.append(MapDestination.space(place: place))
                        }
                    )
                    .padding(.bottom, 90)
                }
            }
            .overlay {
                if !store.state.isNetworkConnected {
                    AlertView(type: .network) {
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
            .navigationDestination(for: MapDestination.self) { destination in
                switch destination {
                case .space(let place):
                    spaceView(place: place) { coordinate, place in
                        navigationPath.append(MapDestination.messageComposer(location: coordinate, place: place))
                    }
                    .onAppear { setTabBarHidden(true) }

                case .messageComposer(let location, let place):
                    messageComposerView(location: location, place: place) {
                        navigationPath.removeLast()
                    }
                    .onAppear { setTabBarHidden(true) }
                }
            }
            .task {
                send(.onAppear(.seoulCity))
            }
            .onChange(of: locationProvider.current) { _, newValue in
                guard didApplyResolvedUserLocation == false else { return }
                guard let coordinate = newValue else { return }

                didApplyResolvedUserLocation = true
                send(.userLocationReady(coordinate))
            }
            .onAppear {
                setTabBarHidden(false)
                locationProvider.startContinuous()
            }
            .onDisappear {
                send(.onDisappear)
                locationProvider.stopContinuous()
            }
            .sheet(isPresented: isTimelineListPresentedBinding) {
                timeLineListView
                    .presentationDetents(.init(arrayLiteral: .medium, .large))
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: isPlaceSearchPresentedBinding) {
                placeSearchOverlay
                    .presentationBackground(.clear)
            }
            .transaction { $0.disablesAnimations = true }
        }
        .toast(toastBinding, bottomPadding: 100)
    }
}

// MARK: - SubViews

private extension MapView {
    var mapViewWrapper: some View {
        MapViewWrapper(
            userLocation: locationProvider.current ?? .seoulCity,
            isFollowingUser: store.state.isFollowingUser,
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
            }
        )
    }

    var floatingNavigationBar: some View {
        FloatingNavigationBar(
            title: Constants.navigationTitle,
            onTapSearch: { send(.tapSearch) }
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
}

// MARK: - Navigation Destination

private extension MapView {
    private func messageComposerView(location: Coordinate, place: Place?, onClose: @escaping () -> Void) -> some View {
        MessageComposerView(
            store: .init(
                currentLocation: location,
                currentPlace: place,
                createMessage: CreateMessageUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                reverseGeocoding: ReverseGeocodeUseCaseImpl(
                    repository: ReverseGeocodeRepositoryImpl(
                        client: NetworkClientImpl()
                    )
                ),
                onClose: { _ in
                    onClose()
                }
            )
        )
    }

    private func spaceView(place: Place, onNavigate: @escaping (Coordinate, Place) -> Void) -> some View {
        SpaceView(
            store: .init(
                fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                place: place
            ),
            domeEnvironment: .init(dayPart: .afternoon),
            place: place,
            onNavigate: { coordinate, place in
                onNavigate(coordinate, place)
            }
        )
    }
}

// MARK: - Sheet & Overlay

private extension MapView {
    @ViewBuilder
    var placeSearchOverlay: some View {
        if let current = locationProvider.current {
            PlaceSearchOverlayView(
                store: PlaceSearchStore(
                    searchPlaces: SearchNearbyPlaceUseCaseImpl(
                        placeRepository: NaverPlaceSearchRepositoryImpl(
                            network: NetworkClientImpl()
                        )
                    ),
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
            }}
        )
    }

    var timeLineListView: some View {
        TimelineListView(
            store: TimelineListStore(
                fetchRecentMessagesUseCase: FetchRecentMessagesUseCaseImpl(
                    repository: MessageRepositoryImpl()
                ),
                deleteMessagesUseCase: DeleteMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl())
            ),
            configuration: .bottomSheet
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

#Preview {
    let rotationAnimator = MessageRotationAnimator()
    let bubbleImageRenderer = BubbleImageRenderer()
    let messageMarkerManager = MessageMarkerManager(
        rotationAnimator: rotationAnimator,
        bubbleImageRenderer: bubbleImageRenderer
    )

    return MapView(
        store: MapStore(
            getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(
                messageRepository: MessageRepositoryImpl(storage: MessageInMemoryStorage.shared)
            ),
            networkMonitor: NetworkMonitor()
        ),
        messageMarkerManager: messageMarkerManager
    )
    .environmentObject(LocationProvider())
}
