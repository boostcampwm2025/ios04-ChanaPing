//
//  SettingStore.swift
//  Meomun
//
//  Created by hoon on 1/29/26.
//

import Combine
import Foundation

final class SettingStore: Store {
    struct State: Equatable {
        var resetAlert: MMAlertModel?
    }

    enum Intent: Equatable {
        case tapOpenAppSettings
        case tapResetAppData
        case dismissResetAlert
        case confirmResetAppData
    }

    enum Action: Equatable {
        case setResetAlert(MMAlertModel?)
    }

    @Published var state: State

    private let appSettingsOpener: AppSettingsOpening
    private let resetMessagesUseCase: ResetMessagesUseCase

    init(appSettingsOpener: AppSettingsOpening, resetMessagesUseCase: ResetMessagesUseCase) {
        self.state = State()
        self.appSettingsOpener = appSettingsOpener
        self.resetMessagesUseCase = resetMessagesUseCase
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .tapOpenAppSettings:
                openAppSettings()
                continuation.finish()

            case .tapResetAppData:
                let alert = MMAlertFactory.resetAllData(
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
                Task {
                    try await AppDataResetter.resetLocalData(resetUseCase: resetMessagesUseCase)
                }
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
    static func resetLocalData(resetUseCase: ResetMessagesUseCase) async throws {
        // 1) UserDefaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            UserDefaults.standard.synchronize()
        }

        // 2) URLCache (이미지/응답 캐시 등)
        URLCache.shared.removeAllCachedResponses()

        // 3) SwiftData
        try await resetUseCase.execute()
    }
}
