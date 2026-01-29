//
//  PermissionStatusRow.swift
//  Meomun
//
//  Created by hoon on 1/28/26.
//

import SwiftUI

struct PermissionStatusRow: View {
    enum StatusKind {
        case good
        case warning
        case bad
        case unknown
    }

    let title: String
    let status: String
    let statusKind: StatusKind

    private var statusColor: Color {
        switch statusKind {
        case .good:
            return .green
        case .warning:
            return .orange
        case .bad:
            return .red
        case .unknown:
            return .secondary
        }
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .font(.footnote)
                .foregroundColor(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(status)
    }
}
