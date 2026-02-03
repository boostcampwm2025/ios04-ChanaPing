//
//  BubbleBackgroundDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

final class BubbleBackgroundDrawer: BubbleDrawable {
    private let rect: CGRect
    private let cornerRadius: CGFloat

    init(rect: CGRect, cornerRadius: CGFloat = BubbleLayoutConstants.cornerRadius) {
        self.rect = rect
        self.cornerRadius = cornerRadius
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let backgroundColor = BubbleStyleConstants.Colors.background(colorScheme)

        // 그림자 설정
        context.setShadow(
            offset: BubbleStyleConstants.Shadow.offset,
            blur: BubbleStyleConstants.Shadow.radius,
            color: BubbleStyleConstants.Shadow.color.cgColor
        )

        // 배경 그리기
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        context.setFillColor(backgroundColor.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
}
