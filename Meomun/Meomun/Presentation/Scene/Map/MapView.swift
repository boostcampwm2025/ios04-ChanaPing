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

    @ObservedObject private var store: MapStore
    @EnvironmentObject private var locationProvider: LocationProvider

    private let messageMarkerManager: MessageMarkerManager
    private let initialUserLocation: Coordinate

    init(
        store: MapStore,
        userLocation: Coordinate,
        messageMarkerManager: MessageMarkerManager
    ) {
        self.store = store
        self.messageMarkerManager = messageMarkerManager
        self.initialUserLocation = userLocation
    }

    private func send(_ intent: MapStore.Intent) {
        Task { await store.send(intent: intent) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                MapViewWrapper(
                    userLocation: initialUserLocation,
                    markerManager: messageMarkerManager,
                    messages: store.state.messages,
                    cameraMoveTarget: store.state.cameraMoveTarget,
                    onCameraMoveConsumed: {
                        send(.cameraMoveConsumed)
                    },
                    onTapPlace: { place in
                        navigationPath.append(MapDestination.space(place: place))
                    },
                    onTapNoPlace: { messages in
                        send(.tapNoPlaceMarker(messages))
                    },
                    onCameraIdle: { coordinate, bounds, snapshot in
                        send(.cameraDidIdle(coordinate, bounds, snapshot))
                    },
                    onCameraChangedByLocation: { coordinate, bounds, snapshot in
                        send(.cameraChangedByLocation(coordinate, bounds, snapshot))
                    }
                )
                .ignoresSafeArea()

                VStack {
                    FloatingNavigationBar(
                        title: Constants.navigationTitle,
                        onTapSearch: { send(.tapSearch) }
                    )

                    Spacer()

                    HStack {
                        Spacer()

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
                .padding(.top, 12)
                .padding(.bottom, 96)
                .ignoresSafeArea(.keyboard, edges: .bottom)

                if !store.state.isNetworkConnected {
                    AlertView(type: .network) {
                        send(.tapNetworkRefresh)
                    }
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { store.state.selectedNoPlaceMessages.isEmpty == false },
                    set: { isPresented in
                        if !isPresented {
                            send(.dismissTimelineView)
                        }
                    }
                )
            ) {
                TimelineListView(
                    store: TimelineListStore(
                        fetchRecentMessagesUseCase: FetchRecentMessagesUseCaseImpl(
                            repository: MessageRepositoryImpl()
                        ),
                        deleteMessagesUseCase: DeleteMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl())
                    ),
                    configuration: .bottomSheet
                )
                    .presentationDetents(.init(arrayLiteral: .medium, .large))
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(for: MapDestination.self) { destination in
                switch destination {
                case .space(let place):
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
                            navigationPath.append(
                                MapDestination.messageComposer(
                                    location: coordinate,
                                    place: place
                                )
                            )
                        }
                    )
                    .onAppear { setTabBarHidden(true) }

                case .messageComposer(let location, let place):
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
                                navigationPath.removeLast()
                            }
                        )
                    )
                    .onAppear { setTabBarHidden(true) }
                }
            }
            .task {
                send(.onAppear(initialUserLocation))
            }
            .onAppear { setTabBarHidden(false) }
            .onDisappear {
                send(.onDisappear)
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
            getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl()),
            networkMonitor: NetworkMonitor()
        ),
        userLocation: .init(latitude: 37.5665, longitude: 126.9780),
        messageMarkerManager: messageMarkerManager
    )
}
