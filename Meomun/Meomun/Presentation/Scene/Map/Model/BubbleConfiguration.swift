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
    var currentMessage: Message
    var nextMessage: Message

    init(
        marker: NMFMarker,
        messages: [Message],
        currentIndex: Int,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double,
        isAnimating: Bool,
        currentMessage: Message,
        nextMessage: Message
    ) {
        self.marker = marker
        self.messages = messages
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
        self.currentMessage = currentMessage
        self.nextMessage = nextMessage
    }
}
