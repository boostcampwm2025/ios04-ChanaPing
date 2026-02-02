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
            Image(systemName: "plus")
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 55, height: 55)
                .background(
                    CornerRadiusShape(
                        topLeft: 50,
                        topRight: 20,
                        bottomLeft: 20,
                        bottomRight: 20
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
