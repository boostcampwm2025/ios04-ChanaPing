//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct MapView: View {
    @StateObject private var store = MapStore()

    var body: some View {
        NavigationStack {
            ZStack {
                MapViewWrapper(
                    groupedMessages: store.state.groupedMessages,
                    onTapPlace: { place in
                        Task {
                            await store.send(intent: .tapPlaceMarker(place))
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
                MessageComposeView()
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
                    SpaceView(environment: .init(weather: .sunny, dayPart: .afternoon))
                }
            }
            .task {
                await store.send(intent: .onAppear)
            }
            .onDisappear {
                Task {
                    await store.send(intent: .onDisappear)
                }
            }
        }
    }
}

#Preview {
    MapView()
}
