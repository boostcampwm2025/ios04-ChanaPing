//
//  ConfirmButton.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct ConfirmButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: 16))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.mmPoint)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
    }
}

#Preview {
    ConfirmButton(action: {})
}
