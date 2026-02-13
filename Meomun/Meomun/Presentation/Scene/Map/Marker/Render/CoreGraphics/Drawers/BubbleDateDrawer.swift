//
//  BubbleDateDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleDateDrawer: BubbleDrawable {
    private let dateString: String
    private let point: CGPoint
    private let maxWidth: CGFloat
    private let alpha: CGFloat
    private let yOffset: CGFloat

    init(
        dateString: String,
        point: CGPoint,
        maxWidth: CGFloat,
        alpha: CGFloat = 1.0,
        yOffset: CGFloat = 0
    ) {
        self.dateString = dateString
        self.point = point
        self.maxWidth = maxWidth
        self.alpha = alpha
        self.yOffset = yOffset
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        context.saveGState()

        context.setAlpha(alpha)
        context.translateBy(x: 0, y: yOffset)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: BubbleStyleConstants.Fonts.date,
            .foregroundColor: BubbleStyleConstants.Colors.textSecondary
        ]

        let attributedString = NSAttributedString(
            string: dateString,
            attributes: attributes
        )

        // 오른쪽 정렬
        let textSize = attributedString.size()
        let alignedPoint = CGPoint(x: point.x + maxWidth - textSize.width, y: point.y)

        attributedString.draw(at: alignedPoint)

        context.restoreGState()
    }
}
