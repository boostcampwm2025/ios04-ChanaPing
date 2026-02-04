//
//  MarkerFadeAnimator.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit

protocol MarkerFadeAnimating {
    func applyFadeIn(
        _ image: UIImage,
        to marker: MarkerProtocol,
        key: MarkerGroupKey
    ) async
}

struct MarkerFadeAnimator: MarkerFadeAnimating {
    let duration: TimeInterval
    let fps: Double

    init(duration: TimeInterval = 0.5, fps: Double = 60) {
        self.duration = duration
        self.fps = fps
    }

    func applyFadeIn(
        _ image: UIImage,
        to marker: MarkerProtocol,
        key: MarkerGroupKey
    ) async {
        // 아이콘은 먼저 교체
        marker.setIcon(image)

        // 시작은 투명
        marker.alpha = 0.0

        let totalFrames = max(1, Int(duration * fps))
        let frameNanos = UInt64(1_000_000_000 / fps)

        for i in 0...totalFrames {
            if Task.isCancelled { return }
            marker.alpha = CGFloat(Double(i) / Double(totalFrames))
            try? await Task.sleep(nanoseconds: frameNanos)
        }

        marker.alpha = 1.0
    }
}
