//
//  SplashReadyEnvironment.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

// Map에서 Root로 지도 준비 여부 알리기용 EnvironmentKey

private struct SplashReadyKey: EnvironmentKey {
    static let defaultValue: () -> Void = { }
}

extension EnvironmentValues {
    var setSplashReady: () -> Void {
        get { self[SplashReadyKey.self] }
        set { self[SplashReadyKey.self] = newValue }
    }
}
