//
//  AppDataConfig.swift
//  Meomun
//
//  Created by Hayeon Park on 2/2/26.
//

import SwiftData

enum AppDataConfig {
    static let schema = Schema([
        PlaceModel.self,
        MessageModel.self
    ])

    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData ModelContainer 생성에 실패했습니다. \(error)")
        }
    }
}
