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
                    .task {
                        // 프로파일링용 더미 데이터 생성
                        do {
                            if let storage: MessageSwiftDataStorage = DIContainer.resolve() {
                                try await storage.seedProfilingData(markerCount: 10)
                                AppLog.info("프로파일링 더미 데이터 생성 완료", category: .main)
                            }
                        } catch {
                            AppLog.error("프로파일링 더미 데이터 생성 실패", category: .main, error: error)
                        }
                    }
            } else {
                DIErrorFallbackView()
                    .onAppear {
                        AppLog.error("DIContainer resolve failed at app launch", category: .diContainer)
                    }
            }
        }
    }
}
