//
//  FloatingContainerModifier.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

import SwiftUI

struct FloatingContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minHeight: 25)  // FloatingTabItem 내용물 기준 최소 높이
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .background(
                CornerRadiusShape(
                    topLeft: 24,
                    topRight: 24,
                    bottomLeft: 10,
                    bottomRight: 10
                )
                .fill(Color.mmFloatingBackground)
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
    func floatingContainer() -> some View {
        modifier(FloatingContainerModifier())
    }
}
