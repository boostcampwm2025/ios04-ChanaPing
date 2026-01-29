//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import CoreLocation
import SwiftUI

struct RootView: View {
    @StateObject private var locationProvider = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase

    @State private var showLocationAlert = false

    private let appSettingsOpener = AppSettingsOpener()

    var body: some View {
        MainTabShellView()
            .environmentObject(locationProvider)
            .ignoresSafeArea(.keyboard)
            .overlay {
                if showLocationAlert {
                    AlertView(type: .location) {
                        Task { await appSettingsOpener.openAppSettings() }
                    }
                }
            }
            .onReceive(locationProvider.$authorizationStatus) { status in
                switch status {
                case .denied, .restricted:
                    showLocationAlert = true
                case .authorizedWhenInUse, .authorizedAlways:
                    showLocationAlert = false
                default:
                    break
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                locationProvider.requestAuthorizationIfNeeded()

                let status = locationProvider.authorizationStatus
                showLocationAlert = (status == .denied || status == .restricted)
            }
    }
}

#Preview {
    RootView()
}
