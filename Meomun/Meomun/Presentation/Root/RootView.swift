//
//  RootView.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @State private var userLocation: Coordinate? = nil

    var body: some View {
        if let userLocation {
            MainTabShellView(userLocation: userLocation)
        } else {
            LocationGateView { coordinate in
                self.userLocation = coordinate
            }
        }
    }
}

#Preview {
    RootView()
}
