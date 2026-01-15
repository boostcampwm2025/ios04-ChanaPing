//
//  BubbleConfiguration.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import NMapsMap

/// 회전 버블 애니메이션 상태를 관리하는 클래스
final class BubbleConfiguration {
    let marker: NMFMarker
    let messages: [Message]
    var currentIndex: Int
    var lastRotationTime: TimeInterval
    var animationStartTime: TimeInterval?
    var animationProgress: Double
    var isAnimating: Bool

    var currentMessage: Message {
        return messages[currentIndex]
    }

    var nextMessage: Message {
        let nextIndex = (currentIndex + 1) % messages.count
        return messages[nextIndex]
    }

    init(
        marker: NMFMarker,
        messages: [Message],
        currentIndex: Int = 0,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double = 0.0,
        isAnimating: Bool = false
    ) {
        self.marker = marker
        self.messages = messages
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
    }

    /// 다음 메시지로 전환 (애니메이션 완료 시 호출)
    func advanceToNext(at currentTime: TimeInterval) {
        guard !messages.isEmpty else { return }

        let nextIndex = (currentIndex + 1) % messages.count
        currentIndex = nextIndex
        isAnimating = false
        animationProgress = 0.0
        animationStartTime = nil
        lastRotationTime = currentTime
    }

    /// 애니메이션 시작 상태로 전환
    func startAnimation(at currentTime: TimeInterval) {
        guard !isAnimating else { return }

        isAnimating = true
        animationStartTime = currentTime
        animationProgress = 0.0
    }
}
