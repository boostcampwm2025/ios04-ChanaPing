//
//  IsSplashVisible.swift
//  Meomun
//
//  Created by 지연 on 2/5/26.
//

import SwiftUI

private struct IsSplashVisibleKey: EnvironmentKey {
    static let defaultValue: Bool = true
}
extension EnvironmentValues {
    var isSplashVisible: Bool {
        get { self[IsSplashVisibleKey.self] }
        set { self[IsSplashVisibleKey.self] = newValue }
    }
}
