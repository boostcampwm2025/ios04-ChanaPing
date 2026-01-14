//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct MapView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden
    @StateObject private var store: MapStore

    let userLocation: Coordinate

    init(userLocation: Coordinate) {
        self.userLocation = userLocation
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
                    .onDisappear { setTabBarHidden(false) }
            }
            .task {
                await store.send(intent: .onAppear)
            }
            .onAppear { setTabBarHidden(false) }
            .onDisappear {
                Task {
                    await store.send(intent: .onDisappear)
                }
            }
            .onChange(of: userLocation) { _, newValue in
                Task {
                    await store.send(intent: .updateUserLocation(newValue))
                }
            }
        }
    }
}
