//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var locationProvider: LocationProvider
    @StateObject private var store: RootStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let provider = LocationProvider()
        _locationProvider = StateObject(wrappedValue: provider)
        _store = StateObject(
            wrappedValue: RootStore(
                locationProvider: provider,
                appSettingsOpener: AppSettingsOpener()
            )
        )
    }

    var body: some View {
        MainTabShellView()
            .environmentObject(locationProvider)
            .ignoresSafeArea(.keyboard)
            .overlay {
                if store.state.showLocationAlert {
                    MMAlertView(type: .location) {
                        Task { await store.send(intent: .tapOpenSettings) }
                    }
                }
            }
            .onReceive(locationProvider.$authorizationStatus) { status in
                Task { await store.send(intent: .authorizationStatusChanged(status)) }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task { await store.send(intent: .appBecameActive) }
            }
    }
}

#Preview {
    RootView()
}
