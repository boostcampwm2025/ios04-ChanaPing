//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var locationProvider = LocationProvider()
    @State private var userLocation: Coordinate? = nil

    var body: some View {
        Group {
            #if DEBUG
            MainTabShellView(userLocation: .init(latitude: 37.5665, longitude: 126.9780))
            #endif
            if let userLocation {
                MainTabShellView(userLocation: userLocation)
            } else {
                LocationGateView { coordinate in
                    self.userLocation = coordinate
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
