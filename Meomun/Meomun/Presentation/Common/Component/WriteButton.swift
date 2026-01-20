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
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 61, height: 61)
                .background(
                    LeftTopCutRoundedShape()
                        .fill(Color.meomunWriteButton)
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
