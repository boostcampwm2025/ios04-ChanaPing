//
//  BubbleLocationDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

final class BubbleLocationDrawer: BubbleDrawable {
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
            .foregroundColor: BubbleStyleConstants.Colors.textSecondary(colorScheme)
        ]

        let attributedString = NSAttributedString(
            string: locationName,
            attributes: attributes
        )

        attributedString.draw(at: textPoint)
    }

    private func drawMappinIcon(at point: CGPoint, in context: CGContext) {
        // SF Symbol "mappin.and.ellipse" 그리기
        if let icon = UIImage(systemName: "mappin.and.ellipse") {
            let iconSize = BubbleLayoutConstants.locationIconSize
            let iconRect = CGRect(
                x: point.x,
                y: point.y,
                width: iconSize,
                height: iconSize
            )
            let tintedIcon = icon.withTintColor(
                BubbleStyleConstants.Colors.locationIconColor,
                renderingMode: .alwaysOriginal
            )
            tintedIcon.draw(in: iconRect)
        }
    }
}
