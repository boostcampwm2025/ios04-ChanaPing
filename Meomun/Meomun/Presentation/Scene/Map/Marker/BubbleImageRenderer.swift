//
//  BubbleImageRenderer.swift
//  Meomun
//
//  Created by MinwooJe on 1/15/26.
//

import SwiftUI
import UIKit

/// 마커 이미지 렌더링을 담당하는 클래스
@MainActor
final class BubbleImageRenderer {

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

        return await render(view: safeBubble, scale: scale ?? UIScreen.main.scale)
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
        let bubble = DecoratedMessageBubble(
            message: current,
            layout: .fixedSize(rotatingBubbleWidth),
            rotating: (current: current, next: next, progress: progress)
        ) { _ in
            RotatingMessageStack(
                current: current,
                next: next,
                progress: progress
            )
        }

        let safeBubble = bubble
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
            .padding(.bottom, current.placeTag != nil ? 90 : 30)
            .offset(y: current.placeTag != nil ? 80 : 0)

        return await render(view: safeBubble, scale: scale ?? UIScreen.main.scale)
    }
}

extension BubbleImageRenderer {
    private func render<V: View>(view: V, scale: CGFloat) async -> UIImage {
        await Task.yield()

        let content = view.environment(\.colorScheme, currentColorScheme)

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
}

extension BubbleImageRenderer {
    /// trait에 맞춰 렌더링 할 색 모드를 설정합니다.
    func setColorScheme(_ traitCollection: UITraitCollection) {
        currentColorScheme = traitCollection.userInterfaceStyle == .light ? .light : .dark
    }
}
