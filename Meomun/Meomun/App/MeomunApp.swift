//
//  MeomunApp.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI
import SwiftData

@main
struct MeomunApp: App {
    var meomunModelContainer: ModelContainer = AppDataConfig.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await MessageSwiftDataStorage.shared.configure(container: meomunModelContainer)
                }
        }
    }
}
