//
//  StubRotationAnimator.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@testable import Meomun
import Foundation

struct StubRotationAnimator: MessageRotationAnimating {
    func shouldStartAnimation(for state: BubbleAnimationState, currentTime: TimeInterval) -> Bool { false }
    func updateAnimation(for state: inout BubbleAnimationState, currentTime: TimeInterval) {}
}
