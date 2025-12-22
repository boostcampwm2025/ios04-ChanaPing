//
//  WriteButton.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct LeftTopCutRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 22
        let cutRadius: CGFloat = 34   // 왼쪽 상단만 더 큼

        var path = Path()

        path.move(to: CGPoint(x: cutRadius, y: 0))

        // top
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: radius),
            control: CGPoint(x: rect.maxX, y: 0)
        )

        // right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // bottom
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - radius),
            control: CGPoint(x: 0, y: rect.maxY)
        )

        // left
        path.addLine(to: CGPoint(x: 0, y: cutRadius))
        path.addQuadCurve(
            to: CGPoint(x: cutRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.closeSubpath()
        return path
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
