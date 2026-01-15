//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct MapView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden
    @EnvironmentObject private var locationProvider: LocationProvider
    @StateObject private var store: MapStore

    private let messageMarkerManager: MessageMarkerManager

    init(
        userLocation: Coordinate,
        messageMarkerManager: MessageMarkerManager
    ) {
        _store = StateObject(wrappedValue: MapStore(userLocation: userLocation))
        self.messageMarkerManager = messageMarkerManager
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapViewWrapper(
                    userLocation: store.state.userLocation,
                    markerManager: messageMarkerManager,
                    messages: store.state.messages,
                    onTapPlace: { place in
                        Task {
                            await store.send(intent: .tapPlaceMarker(place))
                        }
                    },
                    onTapNoPlace: { messages in
                        // TODO: NoPlace 2개 이상 터치 시 UI(스택 펼치기 등) 연결 예정
                        print("NoPlace messages tapped: \(messages.count)")
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
                            Task {
                                await store.send(intent: .tapWriteButton)
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { store.state.isShowingAddMessage },
                    set: { isPresented in
                        if !isPresented {
                            Task {
                                await store.send(intent: .dismissAddMessage)
                            }
                        }
                    }
                )
            ) {
                MessageComposerView(
                    store: MessageComposerStore(
                        userLocation: store.state.userLocation,
                        createMessage: CreateMessageUseCaseImpl(
                            messageRepository: MessageRepositoryImpl()
                        )
                    )
                )
                .onAppear { setTabBarHidden(true) }
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { store.state.selectedPlace != nil },
                    set: { isPresented in
                        if !isPresented {
                            Task {
                                await store.send(intent: .dismissSpaceView)
                            }
                        }
                    }
                )
            ) {
                if let place = store.state.selectedPlace {
                    SpaceView(
                        store: SpaceStore(
                            locationProvider: locationProvider,
                            fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                                messageRepository: MessageRepositoryImpl()
                            )
                        ),
                        domeEnvironment: .init(
                            weather: .sunny,
                            dayPart: .afternoon
                        ),
                        place: place
                    )
                }
            }
            .task {
                locationProvider.requestAuthorizationIfNeeded()
                locationProvider.startContinuous()
                await store.send(intent: .onAppear)
            }
            .onAppear { setTabBarHidden(false) }
            .onDisappear {
                locationProvider.stopContinuous()
                Task {
                    await store.send(intent: .onDisappear)
                }
            }
            .onChange(of: locationProvider.current) { _, newValue in
                guard let newValue else { return }
                Task {
                    await store.send(intent: .updateUserLocation(newValue))
                }
            }
        }
    }
}

#Preview {
    let rotationAnimator = MessageRotationAnimator()
    let bubbleImageRenderer = BubbleImageRenderer()
    let messageMarkerManager = MessageMarkerManager(
        rotationAnimator: rotationAnimator,
        bubbleImageRenderer: bubbleImageRenderer
    )

    MapView(
        userLocation: .init(latitude: 37.5665, longitude: 126.9780),
        messageMarkerManager: messageMarkerManager
    )
}
