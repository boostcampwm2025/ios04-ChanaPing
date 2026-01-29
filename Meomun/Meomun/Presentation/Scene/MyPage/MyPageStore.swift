//
//  MyPageStore.swift
//  Meomun
//
//  Created by hoon on 1/29/26.
//

import Combine
import Foundation

final class MyPageStore: Store {
    struct State: Equatable {
        var resetAlert: AlertModel?
    }

    enum Intent: Equatable {
        case tapOpenAppSettings
        case tapResetAppData
        case dismissResetAlert
        case confirmResetAppData
    }

    enum Action: Equatable {
        case setResetAlert(AlertModel?)
    }

    @Published var state: State

    private let appSettingsOpener: AppSettingsOpening

    init(appSettingsOpener: AppSettingsOpening) {
        self.state = State()
        self.appSettingsOpener = appSettingsOpener
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .tapOpenAppSettings:
                openAppSettings()
                continuation.finish()

            case .tapResetAppData:
                let alert = AlertFactory.resetAllData(
                    onCancel: { [weak self] in
                        guard let self else { return }
                        Task {
                            await self.send(intent: .dismissResetAlert)
                        }
                    },
                    onReset: { [weak self] in
                        guard let self else { return }
                        Task {
                            await self.send(intent: .confirmResetAppData)
                        }
                    }
                )
                continuation.yield(.setResetAlert(alert))
                continuation.finish()

            case .dismissResetAlert:
                continuation.yield(.setResetAlert(nil))
                continuation.finish()

            case .confirmResetAppData:
                AppDataResetter.resetLocalData()
                continuation.yield(.setResetAlert(nil))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setResetAlert(let alert):
            newState.resetAlert = alert
        }

        return newState
    }

    private func openAppSettings() {
        Task {
            await appSettingsOpener.openAppSettings()
        }
    }
}

// MARK: - Data Reset

private enum AppDataResetter {
    static func resetLocalData() {
        // 1) UserDefaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            UserDefaults.standard.synchronize()
        }

        // 2) URLCache (이미지/응답 캐시 등)
        URLCache.shared.removeAllCachedResponses()

        // 3) SwiftData
        // TODO: - SwiftData 초기화
    }
}
