//
//  MessageRotationAnimator.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import Foundation

/// 메시지 애니메이션 로직을 관리하는 객체입니다.
final class MessageRotationAnimator {
    private let rotationInterval: TimeInterval
    private let animationDuration: TimeInterval

    init(
        rotationInterval: TimeInterval = 3.0,
        animationDuration: TimeInterval = 1.0
    ) {
        self.rotationInterval = rotationInterval
        self.animationDuration = animationDuration
    }

    /// 애니메이션 시작 여부를 판단합니다.
    func shouldStartAnimation(for state: AnimationState, currentTime: TimeInterval) -> Bool {
        guard state.messages.count > 1 else { return false }
        guard !state.isAnimating else { return false }
        return currentTime - state.lastRotationTime >= rotationInterval
    }

    /// 애니메이션 진행률을 계산합니다.
    func calculateProgress(startTime: TimeInterval, currentTime: TimeInterval) -> Double {
        let elapsed = currentTime - startTime
        return min(elapsed / animationDuration, 1.0)
    }

    /// 애니메이션 상태를 업데이트합니다.
    func updateAnimation(for state: inout AnimationState, currentTime: TimeInterval) {
        guard let startTime = state.animationStartTime else {
            state.isAnimating = false
            return
        }

        let progress = calculateProgress(startTime: startTime, currentTime: currentTime)
        state.animationProgress = progress

        // 애니메이션 완료 시 다음 메시지로 전환
        if progress >= 1.0 {
            state.advanceToNext(at: currentTime)
        }
    }
}
