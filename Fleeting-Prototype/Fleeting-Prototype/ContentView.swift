//
//  ContentView.swift
//  Fleeting-Prototype
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MainMapViewWrapper()
                    .ignoresSafeArea()
            }

            Tab("Dome", systemImage: "field.of.view.wide") {
                DomeScreen()
            }
        }
    }
}

#Preview {
    ContentView()
}
