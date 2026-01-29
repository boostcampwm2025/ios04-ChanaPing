//
//  PlaceTagButton.swift
//  Meomun
//
//  Created by Hayeon Park on 1/7/26.
//

import SwiftUI

struct PlaceTagButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color.meomunPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(.white.opacity(0.6), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.meomunPrimary.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
        .buttonStyle(.plain)
    }
}

#Preview {
    PlaceTagButton(title: "스타벅스 강남역점", action: {})
}
