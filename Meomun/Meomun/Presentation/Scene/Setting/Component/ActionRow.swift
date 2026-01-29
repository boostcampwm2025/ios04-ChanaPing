//
//  ActionRow.swift
//  Meomun
//
//  Created by hoon on 1/29/26.
//

import SwiftUI

struct ActionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
