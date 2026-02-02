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

    @State private var bootReady = false
    @State private var mapReady = false
    @State private var minimumReady = false

    @State private var showSplash = true
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
            MainTabShellView()
                .environmentObject(locationProvider)
                .environment(\.setSplashReady, markMapReady)
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

            if showSplash {
                MMSplashView(progress: loadingProgress)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .task {
            async let progressTask: Void = runProgressLoop()
            async let bootTask: Void = runBootstrap()

            _ = await (progressTask, bootTask)
        }
        .onChange(of: minimumReady) { _, _ in tryCloseSplash() }
        .onChange(of: bootReady) { _, _ in tryCloseSplash() }
        .onChange(of: mapReady) { _, _ in tryCloseSplash() }
    }
}

private extension RootView {
    func runBootstrap() async {
        // TODO: 권한 체크, 네트워크 체크, 로컬 DB 로드, DI 준비 등

        await MainActor.run {
            bootReady = true
        }
    }

    func runProgressLoop() async {
        for i in 0...100 {
            try? await Task.sleep(for: .milliseconds(20))
            loadingProgress = CGFloat(i) / 100
        }

        await MainActor.run {
            minimumReady = true
        }
    }

    @MainActor
    func markMapReady() {
        mapReady = true
    }

    @MainActor
    func tryCloseSplash() {
        guard bootReady, mapReady, minimumReady else { return }
        guard showSplash else { return }

        loadingProgress = 1

        withAnimation(.easeOut(duration: 0.25)) {
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}
