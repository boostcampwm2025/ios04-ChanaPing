//
//  BubbleTextDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleTextDrawer: BubbleDrawable {
    private let text: String
    private let point: CGPoint
    private let maxWidth: CGFloat
    private let alpha: CGFloat
    private let yOffset: CGFloat

    init(
        text: String,
        point: CGPoint,
        maxWidth: CGFloat,
        alpha: CGFloat = 1.0,
        yOffset: CGFloat = 0
    ) {
        self.text = text
        self.point = point
        self.maxWidth = maxWidth
        self.alpha = alpha
        self.yOffset = yOffset
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        context.saveGState()

        // alpha 및 offset 적용
        context.setAlpha(alpha)
        context.translateBy(x: 0, y: yOffset)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: BubbleStyleConstants.Fonts.text,
            .foregroundColor: BubbleStyleConstants.Colors.textPrimary,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        let boundingRect = CGRect(
            x: point.x,
            y: point.y,
            width: maxWidth,
            height: BubbleLayoutConstants.textHeight
        )

        attributedString.draw(
            with: boundingRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )

        context.restoreGState()
    }
}
