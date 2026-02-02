//
//  WriteButton.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct WriteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 61, height: 61)
                .background(
                    CornerRadiusShape(
                        topLeft: 30,
                        topRight: 30,
                        bottomLeft: 30,
                        bottomRight: 5
                    )
                    .fill(Color.mmWriteButton)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 17)
    }
}

#Preview {
    WriteButton(action: {})
}
