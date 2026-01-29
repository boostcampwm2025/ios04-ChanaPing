//
//  PlaceSearchContainerView.swift
//  Meomun
//
//  Created by MinwooJe on 1/7/26.
//

import SwiftUI

struct PlaceSearchContainerView<Content: View>: View {
    private let content: () -> Content

    init(
        content: @escaping () -> Content
    ) {
        self.content = content
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipped()
                .foregroundStyle(Color(hex: "#53808C"))
                .allowsHitTesting(false)

            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.meomunMessageBackground.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.meomunPrimary.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
        .contentShape(Rectangle())
    }
}

#Preview {
    @FocusState var isFocused: Bool

    PlaceSearchContainerView {
        TextField("placeHolder", text: .constant("Text"))
            .focused($isFocused)
    }
}
