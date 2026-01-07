//
//  PlaceTextField.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct PlaceTextField: View {
    @Binding var text: String

    var placeholder: String = "지금 어디에 있나요?"
    var onTap: (() -> Void)?
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image("placeSymbol")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipped()
                .foregroundStyle(Color.meomunPointColor)

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.meomunPrimaryColor)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.meomunPrimaryColor.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 2)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
            onTap?()
        }
    }
}

#Preview {
    PlaceTextField(text: .constant("GABAôN Salon"))
}
