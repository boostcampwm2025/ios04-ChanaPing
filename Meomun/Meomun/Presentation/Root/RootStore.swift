//
//  RootStore.swift
//  Meomun
//
//  Created by hoon on 1/30/26.
//

import Combine
import CoreLocation

final class RootStore: Store {
    enum Intent {
        case appBecameActive
        case authorizationStatusChanged(CLAuthorizationStatus)
        case tapOpenSettings
    }

    enum Action {
        case setShowLocationAlert(Bool)
    }

    struct State {
        var showLocationAlert: Bool = false
    }

    @Published var state: State = .init()

    private let locationProvider: LocationProvider
    private let appSettingsOpener: AppSettingsOpening

    init(
        locationProvider: LocationProvider,
        appSettingsOpener: AppSettingsOpening
    ) {
        self.locationProvider = locationProvider
        self.appSettingsOpener = appSettingsOpener
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .appBecameActive:
                Task { @MainActor in
                    // 앱 복귀/활성화 시 권한 상태 재평가 트리거
                    locationProvider.requestAuthorizationIfNeeded()

                    let shouldShow = Self.shouldShowLocationAlert(status: locationProvider.authorizationStatus)
                    continuation.yield(.setShowLocationAlert(shouldShow))
                    continuation.finish()
                }

            case .authorizationStatusChanged(let status):
                let shouldShow = Self.shouldShowLocationAlert(status: status)
                continuation.yield(.setShowLocationAlert(shouldShow))
                continuation.finish()

            case .tapOpenSettings:
                Task { @MainActor in
                    await appSettingsOpener.openAppSettings()
                    continuation.finish()
                }
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setShowLocationAlert(let shouldShow):
            newState.showLocationAlert = shouldShow
        }

        return newState
    }

    private static func shouldShowLocationAlert(status: CLAuthorizationStatus) -> Bool {
        status == .denied || status == .restricted
    }
}
