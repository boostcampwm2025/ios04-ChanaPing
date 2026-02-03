//
//  BubbleDrawableFactory.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import Foundation
import SwiftUI

/// Drawable 배열 생성 팩토리
@MainActor
final class BubbleDrawableFactory {
    /// 회전 버블용 Drawable 배열 생성
    static func makeRotatingBubble(
        current: Message,
        next: Message,
        progress: Double,
        rect: CGRect
    ) -> [BubbleDrawable] {
        var drawables: [BubbleDrawable] = []
        let hasPlaceTag = current.placeTag != nil

        // Y 좌표 계산 (동일 로직)
        let contentTop = rect.minY + BubbleLayoutConstants.paddingTop + BubbleLayoutConstants.paddingVertical
        let locationY = contentTop + BubbleLayoutConstants.locationTopPadding
        let locationHeight: CGFloat = 20
        let textY = locationY + locationHeight + BubbleLayoutConstants.sectionSpacing
        let dateY = textY + BubbleLayoutConstants.textHeight + BubbleLayoutConstants.sectionSpacing

        let locationPoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: locationY)
        let textPoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: textY)
        let datePoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: dateY)
        let textWidth = BubbleLayoutConstants.width - 2 * BubbleLayoutConstants.paddingHorizontal

        // 1. StackBack (noPlace만)
        if !hasPlaceTag {
            drawables.append(BubbleStackBackDrawer(rect: rect))
        }

        // 2. 배경
        drawables.append(BubbleBackgroundDrawer(rect: rect))

        // 3. 그라데이션 테두리
        drawables.append(BubbleGradientStrokeDrawer(rect: rect, hasPlaceTag: hasPlaceTag))

        // 4. 위치
        drawables.append(BubbleLocationDrawer(locationName: current.displayLocationName, point: locationPoint))

        // 5-8. 회전 텍스트/날짜 (current + next)
        drawables.append(BubbleTextDrawer(
            text: current.content,
            point: textPoint,
            maxWidth: textWidth,
            alpha: 1 - progress,
            yOffset: -progress * BubbleLayoutConstants.rotationMovingDistance))
        drawables.append(BubbleDateDrawer(
            dateString: current.displayDateString(using: AppConfig.timestampFormatter),
            point: datePoint,
            maxWidth: textWidth,
            alpha: 1 - progress,
            yOffset: -progress * BubbleLayoutConstants.rotationMovingDistance
        ))
        drawables.append(BubbleTextDrawer(
            text: next.content,
            point: textPoint,
            maxWidth: textWidth,
            alpha: progress,
            yOffset: (1 - progress) * BubbleLayoutConstants.rotationMovingDistance
        ))
        drawables.append(BubbleDateDrawer(
            dateString: next.displayDateString(using: AppConfig.timestampFormatter),
            point: datePoint,
            maxWidth: textWidth,
            alpha: progress,
            yOffset: (1 - progress) * BubbleLayoutConstants.rotationMovingDistance
        ))

        // 9. PlaceIcon (조건부)
        if hasPlaceTag {
            let iconCenter = CGPoint(
                x: rect.midX,
                y: rect.minY + BubbleLayoutConstants.placeIconOffsetY
            )
            drawables.append(BubblePlaceIconDrawer(centerPoint: iconCenter))
        }

        // 10. Chevron (place 버블만)
        if hasPlaceTag {
            let chevronX = rect.maxX - BubbleLayoutConstants.paddingHorizontal
                           - BubbleLayoutConstants.chevronBackgroundSize / 2
            let chevronPoint = CGPoint(x: chevronX, y: rect.midY)
            drawables.append(BubbleChevronDrawer(point: chevronPoint))
        }

        return drawables
    }
}
