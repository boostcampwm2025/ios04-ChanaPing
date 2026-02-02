//
//  ComposeTopBar.swift
//  Meomun
//
//  Created by 지연 on 2/3/26.
//

import SwiftUI

struct ComposeTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 6)

            HStack {
                BackButton(action: onBack)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}
