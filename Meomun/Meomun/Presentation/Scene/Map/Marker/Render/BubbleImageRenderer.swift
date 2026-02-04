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

    init(rotatingBubbleWidth: CGFloat = 170) {
        self.rotatingBubbleWidth = rotatingBubbleWidth
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
        let size = CGSize(
            width: BubbleLayoutConstants.width + 60,  // padding 30 좌우
            height: BubbleLayoutConstants.height + 80 + (hasPlaceTag ? 90 : 30)
        )
        let rect = CGRect(
            x: 30,
            y: 40 + (hasPlaceTag ? 80 : 0),
            width: BubbleLayoutConstants.width,
            height: BubbleLayoutConstants.height
        )

        // Factory로 Drawable 생성
        let drawables = BubbleDrawableFactory.makeRotatingBubble(
            current: current,
            next: next,
            progress: progress,
            rect: rect
        )

        // Compositor로 렌더링
        let compositor = BubbleCompositor(
            size: size,
            colorScheme: currentColorScheme
        )

        return compositor.render(drawables: drawables)
    }
}
