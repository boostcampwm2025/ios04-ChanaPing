//
//  MeomunApp.swift
//  Meomun
//
//  Created by Hayeon Park on 12/19/25.
//

import SwiftUI

@main
struct MeomunApp: App {
    init() {
        _ = SupabaseService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
