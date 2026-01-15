//
//  BubbleAnimationState.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import Foundation

/// 버블 애니메이션 상태
struct BubbleAnimationState {
    private let messagesProvider: () -> [Message]       // 데이터 중복 방지를 위해 클로저를 저장

    var currentIndex: Int
    var lastRotationTime: TimeInterval
    var animationStartTime: TimeInterval?
    var animationProgress: Double
    var isAnimating: Bool

    var messages: [Message] {
        messagesProvider()
    }

    var currentMessage: Message? {
        guard !messages.isEmpty else { return nil }
        let safeIndex = currentIndex % messages.count
        return messages[safeIndex]
    }

    var nextMessage: Message? {
        guard messages.count > 1 else { return nil }
        let nextIndex = (currentIndex + 1) % messages.count
        return messages[nextIndex]
    }

    init(
        messagesProvider: @escaping () -> [Message],
        currentIndex: Int = 0,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double = 0.0,
        isAnimating: Bool = false
    ) {
        self.messagesProvider = messagesProvider
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
    }

    /// 다음 메시지로 전환 (애니메이션 완료 시 호출)
    mutating func advanceToNext(at currentTime: TimeInterval) {
        guard !messages.isEmpty else { return }

        let nextIndex = (currentIndex + 1) % messages.count
        currentIndex = nextIndex
        isAnimating = false
        animationProgress = 0.0
        animationStartTime = nil
        lastRotationTime = currentTime
    }

    /// 애니메이션 시작 상태로 전환
    mutating func startAnimation(at currentTime: TimeInterval) {
        guard !isAnimating else { return }

        isAnimating = true
        animationStartTime = currentTime
        animationProgress = 0.0
    }
}
