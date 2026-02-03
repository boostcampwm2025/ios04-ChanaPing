//
//  BubbleStackBackDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleStackBackDrawer: BubbleDrawable {
    private let rect: CGRect

    init(rect: CGRect) {
        self.rect = rect
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let cornerRadius = BubbleLayoutConstants.cornerRadius

        // 첫 번째 배경 (offset1)
        drawStackLayer(
            in: context,
            rect: rect,
            offset: BubbleLayoutConstants.stackBackOffset1,
            color: BubbleStyleConstants.Colors.stackBack1,
            cornerRadius: cornerRadius
        )

        // 두 번째 배경 (offset2)
        drawStackLayer(
            in: context,
            rect: rect,
            offset: BubbleLayoutConstants.stackBackOffset2,
            color: BubbleStyleConstants.Colors.stackBack2,
            cornerRadius: cornerRadius
        )
    }

    private func drawStackLayer(
        in context: CGContext,
        rect: CGRect,
        offset: CGSize,
        color: UIColor,
        cornerRadius: CGFloat
    ) {
        let offsetRect = rect.offsetBy(dx: offset.width, dy: offset.height)
        let path = UIBezierPath(
            roundedRect: offsetRect,
            cornerRadius: cornerRadius
        )

        context.setFillColor(color.cgColor)
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(0.5)
        context.addPath(path.cgPath)
        context.drawPath(using: .fillStroke)
    }
}
