//
//  MMGradientStrokeModifier.swift
//  Meomun
//
//  Created by MinwooJe on 1/30/26.
//

import SwiftUI

struct MMGradientStrokeModifier: ViewModifier {
    enum GradientColorType {
        case green
        case gray
        case custom([Color])

        var colors: [Color] {
            switch self {
            case .green:
                return [
                    Color.tabActive.opacity(0.75),
                    Color.tabActive.opacity(0.22)
                ]
            case .gray:
                return [
                    Color.gray.opacity(0.65),
                    Color.gray.opacity(0.22)
                ]
            case .custom(let colors):
                return colors
            }
        }
    }

    private let cornerRadius: CGFloat
    private let gradientColorType: GradientColorType
    private let lineWidth: CGFloat
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint

    init(
        cornerRadius: CGFloat,
        gradientColorType: GradientColorType,
        lineWidth: CGFloat = 1,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) {
        self.cornerRadius = cornerRadius
        self.gradientColorType = gradientColorType
        self.lineWidth = lineWidth
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: gradientColorType.colors,
                            startPoint: startPoint,
                            endPoint: endPoint
                        ),
                        lineWidth: lineWidth
                    )
            }
    }
}

extension View {
    /// 머문 그라데이션 외곽선 추가
    func mmGradientStroke(
        cornerRadius: CGFloat,
        gradientColorType: MMGradientStrokeModifier.GradientColorType,
        lineWidth: CGFloat = 1,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        modifier(
            MMGradientStrokeModifier(
                cornerRadius: cornerRadius,
                gradientColorType: gradientColorType,
                lineWidth: lineWidth,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }
}
