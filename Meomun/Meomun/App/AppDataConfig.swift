//
//  AppDataConfig.swift
//  Meomun
//
//  Created by Hayeon Park on 2/2/26.
//

import SwiftData

enum AppDataConfig {
    static let modelList: [any PersistentModel.Type] = [
        PlaceModel.self,
        MessageModel.self
    ]

    static let schema = Schema(modelList)

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
