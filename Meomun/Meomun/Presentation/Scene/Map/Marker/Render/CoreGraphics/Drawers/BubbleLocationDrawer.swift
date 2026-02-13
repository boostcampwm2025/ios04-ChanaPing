//
//  BubbleLocationDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleLocationDrawer: BubbleDrawable {
    private let locationName: String
    private let point: CGPoint

    init(locationName: String, point: CGPoint) {
        self.locationName = locationName
        self.point = point
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        // mappin 아이콘
        let iconPoint = CGPoint(x: point.x, y: point.y)
        drawMappinIcon(at: iconPoint, in: context)

        // 텍스트
        let textPoint = CGPoint(
            x: point.x + BubbleLayoutConstants.locationIconSize + BubbleLayoutConstants.locationIconSpacing,
            y: point.y
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: BubbleStyleConstants.Fonts.location,
            .foregroundColor: BubbleStyleConstants.Colors.textSecondary
        ]

        let attributedString = NSAttributedString(
            string: locationName,
            attributes: attributes
        )

        attributedString.draw(at: textPoint)
    }

    private func drawMappinIcon(at point: CGPoint, in context: CGContext) {
        let iconRect = CGRect(
            x: point.x,
            y: point.y,
            width: BubbleLayoutConstants.locationIconSize,
            height: BubbleLayoutConstants.locationIconSize
        )
        let image = UIImage(resource: .mappinBubble)
        image.draw(in: iconRect)
    }
}
