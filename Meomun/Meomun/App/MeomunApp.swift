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
    var meomunModelContainer: ModelContainer = AppDataConfig.makeContainer()

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
            print("[TipKit] configure failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await MessageSwiftDataStorage.shared.configure(container: meomunModelContainer)
                }
        }
    }
}
