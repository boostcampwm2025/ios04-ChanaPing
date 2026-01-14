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

    init(userLocation: Coordinate) {
        _store = StateObject(wrappedValue: MapStore(userLocation: userLocation))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapViewWrapper(
                    messages: store.state.messages,
                    userLocation: store.state.userLocation
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
                MessageComposerView(userLocation: store.state.userLocation)
                    .onAppear { setTabBarHidden(true) }
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
