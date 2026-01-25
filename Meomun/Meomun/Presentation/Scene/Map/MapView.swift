//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct MapView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden

    @State private var navigationPath = NavigationPath()

    @StateObject private var store: MapStore
    @EnvironmentObject private var locationProvider: LocationProvider

    private let messageMarkerManager: MessageMarkerManager
    private let initialUserLocation: Coordinate

    init(
        userLocation: Coordinate,
        messageMarkerManager: MessageMarkerManager
    ) {
        _store = StateObject(wrappedValue: MapStore(
            getNearbyMessagesUseCase: GetNearbyMessagesUseCaseImpl(
                messageRepository: MessageRepositoryImpl()
            )
        ))
        self.messageMarkerManager = messageMarkerManager
        self.initialUserLocation = userLocation
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                MapViewWrapper(
                    userLocation: initialUserLocation,
                    markerManager: messageMarkerManager,
                    messages: store.state.messages,
                    onTapPlace: { place in
                        navigationPath.append(MapDestination.space(place: place))
                    },
                    onTapNoPlace: { messages in
                        Task {
                            await store.send(intent: .tapNoPlaceMarker(messages))
                        }
                    },
                    onCameraIdle: { coordinate in
                        Task {
                            await store.send(intent: .cameraDidIdle(coordinate))
                        }
                    },
                    onCameraChangedByLocation: { coordinate in
                        Task {
                            await store.send(intent: .cameraChangedByLocation(coordinate))
                        }
                    }
                )
                .ignoresSafeArea()

                VStack {
                    FloatingNavigationBar(
                        title: "머문",
                        onTapSearch: {}
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
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .sheet(
                isPresented: Binding(
                    get: { store.state.selectedNoPlaceMessages.isEmpty == false },
                    set: { isPresented in
                        if !isPresented {
                            Task { await store.send(intent: .dismissTimelineView)}
                        }
                    }
                )
            ) {
                TimelineListView(
                    store: TimelineListStore(
                        initialMessages: store.state.selectedNoPlaceMessages,
                        fetchRecentMessagesUseCase: FetchRecentMessagesUseCaseImpl(
                            repository: MessageRepositoryImpl()
                        )
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
                await store.send(intent: .onAppear(initialUserLocation))
            }
            .onAppear { setTabBarHidden(false) }
            .onDisappear {
                Task {
                    await store.send(intent: .onDisappear)
                }
            }
        }
        .toast(toastBinding, bottomPadding: 100)
    }
}

private extension MapView {
    var toastBinding: Binding<String?> {
        Binding(
            get: { store.state.toastMessage },
            set: { message in
                Task {
                    await store.send(intent: .setToast(message))
                }
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
        userLocation: .init(latitude: 37.5665, longitude: 126.9780),
        messageMarkerManager: messageMarkerManager
    )
}
