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

    /// 베이스 레이어만 반환 (StackBack, 배경, 테두리, PlaceIcon, Chevron). 캐시 키: hasPlaceTag
    static func makeBaseDrawables(rect: CGRect, hasPlaceTag: Bool) -> [BubbleDrawable] {
        var drawables: [BubbleDrawable] = []
        if !hasPlaceTag {
            drawables.append(BubbleStackBackDrawer(rect: rect))
        }
        drawables.append(BubbleBackgroundDrawer(rect: rect))
        drawables.append(BubbleGradientStrokeDrawer(rect: rect, hasPlaceTag: hasPlaceTag))
        if hasPlaceTag {
            let iconCenter = CGPoint(
                x: rect.midX,
                y: rect.minY + BubbleLayoutConstants.placeIconOffsetY
            )
            drawables.append(BubblePlaceIconDrawer(centerPoint: iconCenter))
        }
        if hasPlaceTag {
            let chevronX = rect.maxX - BubbleLayoutConstants.paddingHorizontal
                - BubbleLayoutConstants.chevronBackgroundSize / 2
            let chevronPoint = CGPoint(x: chevronX, y: rect.midY)
            drawables.append(BubbleChevronDrawer(point: chevronPoint))
        }
        return drawables
    }

    /// 위치(장소명/주소) 레이어 1개 반환. 캐시 키: locationText
    static func makeLocationDrawable(rect: CGRect, locationName: String) -> BubbleDrawable {
        let contentTop = rect.minY + BubbleLayoutConstants.paddingTop + BubbleLayoutConstants.paddingVertical
        let locationY = contentTop + BubbleLayoutConstants.locationTopPadding
        let locationPoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: locationY)
        return BubbleLocationDrawer(locationName: locationName, point: locationPoint)
    }

    /// 애니메이션 레이어만 반환 (current/next 텍스트 / 날짜 4개). 매 프레임 그리기용
    static func makeAnimationDrawables(
        current: Message,
        next: Message,
        progress: Double,
        rect: CGRect
    ) -> [BubbleDrawable] {
        let contentTop = rect.minY + BubbleLayoutConstants.paddingTop + BubbleLayoutConstants.paddingVertical
        let locationY = contentTop + BubbleLayoutConstants.locationTopPadding
        let locationHeight: CGFloat = 20
        let textY = locationY + locationHeight + BubbleLayoutConstants.sectionSpacing
        let dateY = textY + BubbleLayoutConstants.textHeight + BubbleLayoutConstants.sectionSpacing
        let textPoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: textY)
        let datePoint = CGPoint(x: rect.minX + BubbleLayoutConstants.paddingHorizontal, y: dateY)
        let textWidth = BubbleLayoutConstants.width - 2 * BubbleLayoutConstants.paddingHorizontal

        return [
            BubbleTextDrawer(
                text: current.content,
                point: textPoint,
                maxWidth: textWidth,
                alpha: 1 - progress,
                yOffset: -progress * BubbleLayoutConstants.rotationMovingDistance
            ),
            BubbleDateDrawer(
                dateString: current.displayDateString(using: AppConfig.timestampFormatter),
                point: datePoint,
                maxWidth: textWidth,
                alpha: 1 - progress,
                yOffset: -progress * BubbleLayoutConstants.rotationMovingDistance
            ),
            BubbleTextDrawer(
                text: next.content,
                point: textPoint,
                maxWidth: textWidth,
                alpha: progress,
                yOffset: (1 - progress) * BubbleLayoutConstants.rotationMovingDistance
            ),
            BubbleDateDrawer(
                dateString: next.displayDateString(using: AppConfig.timestampFormatter),
                point: datePoint,
                maxWidth: textWidth,
                alpha: progress,
                yOffset: (1 - progress) * BubbleLayoutConstants.rotationMovingDistance
            )
        ]
    }
}
