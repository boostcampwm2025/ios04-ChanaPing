//
//  MeomunApp.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct MeomunApp: App {
    init() {
        do {
            #if DEBUG
            // Uncomment while testing tips if they don't appear due to stored display history.
            try Tips.resetDatastore()
            #endif

            try Tips.configure([
                .displayFrequency(.immediate)
            ])
        } catch {
            // TipKit configuration failure should not block app launch.
            AppLog.error("[TipKit] configure failed: \(error)", category: .main)
        }

        DIContainer.registerDependencies()
    }

    var body: some Scene {
        WindowGroup {
            if let locationProvider: LocationProvider = DIContainer.resolve(),
               let rootStore: RootStore = DIContainer.resolve() {
                RootView(locationProvider: locationProvider, store: rootStore)
            } else {
                DIErrorFallbackView()
                    .onAppear {
                        AppLog.error("DIContainer resolve failed at app launch", category: .diContainer)
                    }
            }
        }
    }
}
