//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var locationProvider = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didStartContinuous = false
    @State private var userLocation: Coordinate?

    var body: some View {
        Group {
            if let userLocation {
                MainTabShellView(userLocation: userLocation)
            } else {
                MainTabShellView(userLocation: .seoulCity)
                    .overlay {
                        LocationGateView { coordinate in
                            self.userLocation = coordinate
                        }
                    }
            }
        }
        .environmentObject(locationProvider)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    RootView()
}
