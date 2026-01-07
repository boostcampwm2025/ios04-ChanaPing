//
//  WriteButton.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct LeftTopCutRoundedShape: Shape {
    private let baseRadius: CGFloat = 22
    private let cutRadius: CGFloat = 34

    func path(in rect: CGRect) -> Path {
        CornerRadiusShape(
            topLeft: cutRadius,
            topRight: baseRadius,
            bottomLeft: baseRadius,
            bottomRight: baseRadius
        ).path(in: rect)
    }
}

struct WriteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LeftTopCutRoundedShape()
                        .fill(Color.mamunButton)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
    }
}

#Preview {
    WriteButton(action: {
        MapView()
    })
}
