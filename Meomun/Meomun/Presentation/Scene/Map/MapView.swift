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
    @State private var currentUserLocation: Coordinate?     // TODO: MessageComposerStore에 LocationProvider 주입 후 제거

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
        NavigationStack {
            ZStack {
                MapViewWrapper(
                    userLocation: initialUserLocation,
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
                            Task {
                                do {
                                    let location = try await locationProvider.requestCurrentOnce()
                                    currentUserLocation = location
                                    await store.send(intent: .tapWriteButton)
                                } catch {
                                    // 위치 가져오기 실패 시 에러 처리
                                    AppLog.error("Failed to get current location", category: .location, error: error)
                                    // TODO: 사용자에게 에러 알림 표시
                                }
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
                if let userLocation = currentUserLocation {
                    MessageComposerView(
                        store: MessageComposerStore(
                            userLocation: userLocation,
                            createMessage: CreateMessageUseCaseImpl(
                                messageRepository: MessageRepositoryImpl()
                            ),
                            onClose: {
                                Task { await store.send(intent: .dismissAddMessage)}
                            }
                        )
                    )
                    .onAppear { setTabBarHidden(true) }
                }
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
                await store.send(intent: .onAppear(initialUserLocation))
            }
            .onAppear { setTabBarHidden(false) }
            .onDisappear {
                Task {
                    await store.send(intent: .onDisappear)
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

    return MapView(
        userLocation: .init(latitude: 37.5665, longitude: 126.9780),
        messageMarkerManager: messageMarkerManager
    )
}
