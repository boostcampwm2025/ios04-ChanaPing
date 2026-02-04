//
//  BubblePlaceIconDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubblePlaceIconDrawer: BubbleDrawable {
    private let centerPoint: CGPoint

    init(centerPoint: CGPoint) {
        self.centerPoint = centerPoint
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let iconSize = BubbleLayoutConstants.placeIconSize

        // 배경 원 (흰색)
        let circleCenter = CGPoint(
            x: centerPoint.x,
            y: centerPoint.y + BubbleLayoutConstants.placeIconBackgroundOffset
        )
        let circleRect = CGRect(
            x: circleCenter.x - iconSize / 2,
            y: circleCenter.y - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: circleRect)

        // 아이콘 이미지
        let icon = UIImage(resource: .spaceIcon)

        let iconRect = CGRect(
            x: centerPoint.x - iconSize / 2,
            y: centerPoint.y - iconSize / 2,
            width: iconSize,
            height: iconSize
        )
        icon.draw(in: iconRect)
    }
}
