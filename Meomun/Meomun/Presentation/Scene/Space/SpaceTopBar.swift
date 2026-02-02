//
//  SpaceTopBar.swift
//  Meomun
//
//  Created by 지연 on 2/3/26.
//

import SwiftUI

struct SpaceTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            BackButton(action: onBack)

            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(Color.mmTabActive)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.mmTextBrand)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.mmBackground.opacity(0.8))
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Spacer()
        }
        .padding(.top, 10)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .black.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
}
