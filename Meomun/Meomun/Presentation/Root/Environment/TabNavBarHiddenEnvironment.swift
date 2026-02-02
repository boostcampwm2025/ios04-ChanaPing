//
//  TabNavBarHiddenEnvironment.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

private struct SetNavBarHiddenKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var setNavBarHidden: (Bool) -> Void {
        get { self[SetNavBarHiddenKey.self] }
        set { self[SetNavBarHiddenKey.self] = newValue }
    }
}

private struct SetTabBarHiddenKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var setTabBarHidden: (Bool) -> Void {
        get { self[SetTabBarHiddenKey.self] }
        set { self[SetTabBarHiddenKey.self] = newValue }
    }
}
