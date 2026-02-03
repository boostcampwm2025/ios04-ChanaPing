//
//  BubbleGradientStrokeDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleGradientStrokeDrawer: BubbleDrawable {
    private let rect: CGRect
    private let cornerRadius: CGFloat
    private let colorType: BubbleStyleConstants.GradientStroke.ColorType

    init(
        rect: CGRect,
        cornerRadius: CGFloat = BubbleLayoutConstants.cornerRadius,
        hasPlaceTag: Bool
    ) {
        self.rect = rect
        self.cornerRadius = cornerRadius
        self.colorType = hasPlaceTag ? .green : .gray
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let colors = colorType.colors(colorScheme: colorScheme)
        let cgColors = colors.map { $0.cgColor } as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: cgColors,
            locations: [0, 1]
        ) else { return }

        // 테두리 path
        let path = UIBezierPath(
            roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),  // stroke 중심선 보정
            cornerRadius: cornerRadius
        )

        context.saveGState()

        // 그라데이션 클리핑 영역 설정
        context.setLineWidth(BubbleStyleConstants.GradientStroke.lineWidth)
        context.addPath(path.cgPath)
        context.replacePathWithStrokedPath()
        context.clip()

        // 그라데이션 그리기
        let startPoint = CGPoint(x: rect.minX, y: rect.minY)
        let endPoint = CGPoint(x: rect.maxX, y: rect.maxY)

        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: []
        )

        context.restoreGState()
    }
}
