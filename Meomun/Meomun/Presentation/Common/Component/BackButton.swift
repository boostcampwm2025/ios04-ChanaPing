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
    BackButton(action: {})
}
