//
//  CancelButton.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct CancelButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16))
                .foregroundStyle(Color.meomunDefaultColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.6))
                )
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                .shadow(color: .black.opacity(0.15), radius: 0, x: 1, y: 1)
        }
    }
}

#Preview {
    CancelButton(action: {})
}
