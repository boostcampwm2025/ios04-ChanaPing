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

    init(rotatingBubbleWidth: CGFloat = 170) {
        self.rotatingBubbleWidth = rotatingBubbleWidth
    }

    /// 단일 메시지 버블 이미지를 렌더링합니다.
    /// - Parameters:
    ///   - message: 렌더링할 메시지
    ///   - showsAccentLine: 좌측 상태 라인 표시 여부
    ///   - scale: 렌더링 스케일 (nil이면 화면 스케일 사용)
    func renderSingleBubble(
        message: Message,
        showsAccentLine: Bool,
        scale: CGFloat? = nil
    ) -> UIImage {
        let bubble = MessageBubble(
            placeName: message.placeTag?.name,
            statusIndicator: showsAccentLine ? (message.isRecent() ? .recent : .normal) : .none,
            layout: showsAccentLine ? .flexible : .fixedSize(rotatingBubbleWidth)
        ) {
            BubbleText(text: message.content)
        }

        return render(view: bubble.padding(4), scale: scale ?? UIScreen.main.scale)
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
    ) -> UIImage {
        let bubble = MessageBubble(
            placeName: current.placeTag?.name,
            statusIndicator: .none,
            layout: .fixedSize(rotatingBubbleWidth)
        ) {
            RotatingTextStack(
                currentText: current.content,
                nextText: next.content,
                progress: progress
            )
        }

        return render(view: bubble.padding(4), scale: scale ?? UIScreen.main.scale)
    }

    /// 스택 버블 이미지를 렌더링합니다.
    /// - Parameters:
    ///   - messages: 렌더링 할 메시지들
    ///   - scale: 렌더링 스케일 (nil이면 화면 스케일 사용)
    func renderStackBubble(
        messages: [Message],
        scale: CGFloat? = nil
    ) -> UIImage {
        // TODO: MessageStackBubble 구현 후 교체
        guard let first = messages.first else { return UIImage() }
        return renderSingleBubble(message: first, showsAccentLine: true, scale: scale)
    }
}

extension BubbleImageRenderer {
    private func render<V: View>(view: V, scale: CGFloat) -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
}
