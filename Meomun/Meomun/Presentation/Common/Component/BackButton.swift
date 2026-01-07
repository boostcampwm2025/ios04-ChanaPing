//
//  BackButton.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.system(size: 16))
                .foregroundStyle(Color.meomunPrimaryColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
    }
}

#Preview {
    @Previewable @State var message: String = ""

    VStack(spacing: 20) {
        HStack {
            BackButton(action: {})
            ConfirmButton(action: {})
            WriteButton(action: {})
        }

        MessageTextEditor(text: $message)

        HStack {
            PlaceTextField(text: .constant("GABAôN Salon"))
            CancelButton(action: {})
        }
        PlaceTagSlider(places: ["스타벅스 파주가람점", "ONUTE", "콰이어트라이트", "메가MGC커피 파주별하람마을점"], onSelect: {_ in })
    }
    .padding(.horizontal, 20)
}
