//
//  MMAlertButtonConfig.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import SwiftUI

struct MMAlertButtonConfig {
    enum Role {
        case normal
        case cancel
        case destructive
    }

    let title: String
    let role: Role
    let action: (() -> Void)?

    static let confirm = MMAlertButtonConfig(
        title: "확인",
        role: .normal,
        action: nil
    )
}
