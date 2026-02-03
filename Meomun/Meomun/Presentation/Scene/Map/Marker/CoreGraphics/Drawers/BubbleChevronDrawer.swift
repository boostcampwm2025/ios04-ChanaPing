//
//  BubbleChevronDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

final class BubbleChevronDrawer: BubbleDrawable {
    private let point: CGPoint

    init(point: CGPoint) {
        self.point = point
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let tabActive = BubbleStyleConstants.Colors.tabActive(colorScheme)

        // 배경 원
        let circleSize = BubbleLayoutConstants.chevronBackgroundSize
        let circleRect = CGRect(
            x: point.x - circleSize / 2,
            y: point.y - circleSize / 2,
            width: circleSize,
            height: circleSize
        )

        context.setFillColor(tabActive.withAlphaComponent(0.1).cgColor)
        context.fillEllipse(in: circleRect)

        // Chevron 아이콘
        if let chevron = UIImage(systemName: "chevron.right") {
            let iconSize = BubbleLayoutConstants.chevronIconSize
            let iconRect = CGRect(
                x: point.x - iconSize / 2,
                y: point.y - iconSize / 2,
                width: iconSize,
                height: iconSize
            )
            let tintedChevron = chevron.withTintColor(
                tabActive.withAlphaComponent(0.75),
                renderingMode: .alwaysOriginal
            )
            tintedChevron.draw(in: iconRect)
        }
    }
}
