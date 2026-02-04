//
//  BubbleImageRenderer.swift
//  Meomun
//
//  Created by MinwooJe on 1/15/26.
//

import SwiftUI
import UIKit

@MainActor
protocol BubbleImageRendering {
    func renderSingleBubble(
        message: Message,
        scale: CGFloat?
    ) async -> UIImage

    func renderRotatingBubble(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat?
    ) async -> UIImage
}

extension BubbleImageRendering {
    func renderSingleBubble(message: Message) async -> UIImage {
        await renderSingleBubble(message: message, scale: nil)
    }

    func renderRotatingBubble(current: Message, next: Message, progress: Double) async -> UIImage {
        await renderRotatingBubble(current: current, next: next, progress: progress, scale: nil)
    }
}

/// 마커 이미지 렌더링을 담당하는 클래스
final class BubbleImageRenderer: BubbleImageRendering {

    /// 회전 버블의 고정 너비
    private let rotatingBubbleWidth: CGFloat

    /// 메시지 버블 렌더링 시 다크 모드 대응을 위해
    private var currentColorScheme: ColorScheme = .light

    /// 회전 버블 베이스 / 위치 레이어 캐시 (캐싱만 적용)
    private let bubbleImageCache: BubbleImageCache

    init(rotatingBubbleWidth: CGFloat = 170, bubbleImageCache: BubbleImageCache = BubbleImageCache()) {
        self.rotatingBubbleWidth = rotatingBubbleWidth
        self.bubbleImageCache = bubbleImageCache
    }

    /// 단일 메시지 버블 이미지를 렌더링합니다.
    /// - Parameters:
    ///   - message: 렌더링할 메시지
    ///   - scale: 렌더링 스케일 (nil이면 화면 스케일 사용)
    func renderSingleBubble(
        message: Message,
        scale: CGFloat? = nil
    ) async -> UIImage {
        let bubble = DecoratedMessageBubble(
            message: message,
            layout: .flexible
        )

        let safeBubble = bubble
            .padding(20)
            .offset(y: 10)

        let renderer = ImageRenderer(content: safeBubble)
        renderer.scale = scale ?? UIScreen.main.scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }

    /// 애니메이션 진행도에 따른 회전 버블의 이미지를 렌더링합니다.
    /// 베이스 / 위치 레이어는 캐시하고, 매 프레임은 애니메이션 레이어만 그림.
    /// - Parameters:
    ///   - current: 현재 표시 중인 메시지
    ///   - next: 다음에 표시될 메시지
    ///   - progress: 애니메이션 진행률 (0.0 ~ 1.0)
    ///   - scale: 렌더링 스케일 (nil이면 화면 스케일 사용)
    func renderRotatingBubble(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat? = nil
    ) async -> UIImage {
        let hasPlaceTag = current.placeTag != nil
        let locationText = current.displayLocationName

        // 캔버스 = 버블 + 스택 배경/아이콘 여백만 반영. 스택백 offset, place 아이콘 상단
        let bubbleHeight = BubbleLayoutConstants.height
        let bubbleWidth = BubbleLayoutConstants.width
        let stackBackInset = BubbleLayoutConstants.stackBackOffset1.width
        let placeIconTopInset = BubbleLayoutConstants.placeIconSize

        let size: CGSize
        let rect: CGRect
        if hasPlaceTag {
            size = CGSize(width: bubbleWidth, height: placeIconTopInset + bubbleHeight)
            rect = CGRect(x: 0, y: placeIconTopInset, width: bubbleWidth, height: bubbleHeight)
        } else {
            size = CGSize(width: bubbleWidth + stackBackInset, height: bubbleHeight + stackBackInset)
            rect = CGRect(x: 0, y: 0, width: bubbleWidth, height: bubbleHeight)
        }
        let scaleToUse = scale ?? UIScreen.main.scale
        let compositor = BubbleCompositor(
            size: size,
            colorScheme: currentColorScheme,
            scale: scaleToUse
        )

        // 1. 베이스 이미지 (캐시 hit 시 재사용)
        var baseImage: UIImage
        if let cached = await bubbleImageCache.baseImage(hasPlaceTag: hasPlaceTag) {
            baseImage = cached
        } else {
            let baseDrawables = BubbleDrawableFactory.makeBaseDrawables(rect: rect, hasPlaceTag: hasPlaceTag)
            baseImage = compositor.render(drawables: baseDrawables, opaque: false)
            await bubbleImageCache.setBaseImage(baseImage, hasPlaceTag: hasPlaceTag)
        }

        // 2. 위치 레이어 이미지 (캐시 hit 시 재사용)
        var locationImage: UIImage
        if let cached = await bubbleImageCache.locationTextImage(locationText: locationText) {
            locationImage = cached
        } else {
            let locationDrawable = BubbleDrawableFactory.makeLocationDrawable(rect: rect, locationName: locationText)
            locationImage = compositor.render(drawables: [locationDrawable], opaque: false)
            await bubbleImageCache.setLocationTextImage(locationImage, locationText: locationText)
        }

        // 3. 베이스 + 위치 합성 -> underlay
        let underlay = compositor.composite(base: baseImage, top: locationImage)

        // 4. 애니메이션 레이어만 매 프레임 그리기
        let animationDrawables = BubbleDrawableFactory.makeAnimationDrawables(
            current: current,
            next: next,
            progress: progress,
            rect: rect
        )
        return compositor.render(drawables: animationDrawables, over: underlay, opaque: false)
    }
}
