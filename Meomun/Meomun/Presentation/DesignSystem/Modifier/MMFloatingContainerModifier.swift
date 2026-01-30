//
//  MMFloatingContainerModifier.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

import SwiftUI

struct MMFloatingContainerModifier: ViewModifier {
    private let color: Color
    private let opacity: CGFloat

    init(color: Color, opacity: CGFloat) {
        self.color = color
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .frame(minHeight: 25)  // FloatingTabItem 내용물 기준 최소 높이
            .padding(.horizontal, MMSpacing.floatingInnerHorizontalPadding)
            .padding(.vertical, MMSpacing.floatingVerticalPadding)
            .background(
                CornerRadiusShape(
                    topLeft: MMCornerRadius.floatingContainerTop,
                    topRight: MMCornerRadius.floatingContainerTop,
                    bottomLeft: MMCornerRadius.floatingContainerBottom,
                    bottomRight: MMCornerRadius.floatingContainerBottom
                )
                .fill(color.opacity(opacity))
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 18,
                    x: 0,
                    y: 6
                )
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 5)
    }
}

extension View {
    func mmFloatingContainer(
        color: Color = Color.mmFloatingBackground,
        opacity: CGFloat = 0.85
    ) -> some View {
        modifier(MMFloatingContainerModifier(color: color, opacity: opacity))
    }
}
