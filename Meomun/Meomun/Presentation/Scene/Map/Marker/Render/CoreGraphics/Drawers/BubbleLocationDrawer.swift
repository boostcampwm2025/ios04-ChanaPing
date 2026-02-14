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
    private let hasPlaceTag: Bool
    private let mappinIcon: UIImage

    init(locationName: String, point: CGPoint, hasPlaceTag: Bool) {
        self.locationName = locationName
        self.point = point
        self.hasPlaceTag = hasPlaceTag
        self.mappinIcon = UIImage(resource: .mappinBubble)
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

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: BubbleStyleConstants.Fonts.location,
            .foregroundColor: BubbleStyleConstants.Colors.textSecondary,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(
            string: locationName,
            attributes: attributes
        )

        let chevronSpace: CGFloat = hasPlaceTag
            ? BubbleLayoutConstants.chevronBackgroundSize
            : 0
        let maxTextWidth = BubbleLayoutConstants.width
            - BubbleLayoutConstants.paddingHorizontal
            - BubbleLayoutConstants.locationIconSize
            - BubbleLayoutConstants.locationIconSpacing
            - chevronSpace
            - BubbleLayoutConstants.paddingHorizontal

        let boundingRect = CGRect(
            x: textPoint.x,
            y: textPoint.y,
            width: maxTextWidth,
            height: BubbleLayoutConstants.locationIconSize
        )

        attributedString.draw(
            with: boundingRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
    }

    private func drawMappinIcon(at point: CGPoint, in context: CGContext) {
        let iconRect = CGRect(
            x: point.x,
            y: point.y,
            width: BubbleLayoutConstants.locationIconSize,
            height: BubbleLayoutConstants.locationIconSize
        )
        mappinIcon.draw(in: iconRect)
    }
}
