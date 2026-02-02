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

    @State private var isReady: Bool = false
    @State private var loadingProgress: CGFloat = 0

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
        ZStack {
            if isReady {
                MainTabShellView()
                    .environmentObject(locationProvider)
                    .transition(.opacity)
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
            } else {
                MMSplashView(progress: loadingProgress)
                    .transition(.opacity)
            }
        }
        .task {
            // 앱 준비 작업
            await simulateOrRealLoading()
        }
    }

    private func simulateOrRealLoading() async {
        for i in 0...100 {
            try? await Task.sleep(for: .milliseconds(36))
            loadingProgress = CGFloat(i) / 100
        }
        // 권한 체크, 네트워크 체크, 로컬 DB 로드, di 준비 등

        isReady = true
    }
}

#Preview {
    RootView()
}
