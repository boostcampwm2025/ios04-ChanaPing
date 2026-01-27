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
    var meomunModelContainer: ModelContainer = {
        let schema = Schema([
            PlaceModel.self,
            MessageModel.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("SwiftData ModelContainer 생성에 실패했습니다. \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await MessageSwiftDataStorage.shared.configure(container: meomunModelContainer)
                }
        }
    }
}
