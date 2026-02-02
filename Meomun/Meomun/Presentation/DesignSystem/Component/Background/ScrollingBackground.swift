//
//  ScrollingBackground.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI
import UIKit

struct ScrollingBackground: View {
    let backgroundAssetName: String
    let containerSize: CGSize
    let scrollSpeedPointsPerSecond: CGFloat
    let animationTimeSeconds: CGFloat

    /// 화면보다 얼마나 더 넓게 그릴지 (클수록 안전)
    var renderWidthMultiplier: CGFloat = 3.0

    /// 끝점에서 1~2px 비는 거 방지
    var safetyMarginPoints: CGFloat = 24

    var body: some View {
        let viewportWidth = containerSize.width
        let viewportHeight = containerSize.height

        // 처음부터 넓게 렌더
        let renderWidth = (viewportWidth * max(1.2, renderWidthMultiplier)) + safetyMarginPoints

        // 오른쪽이 안 비는 최대 이동거리
        let maxTravelRange = max(0, renderWidth - viewportWidth - viewportWidth)

        // 왕복 offset (0 ... -maxTravelRange)
        let rawOffsetX = pingPongHorizontalOffset(
            travelRange: maxTravelRange,
            speedPointsPerSecond: scrollSpeedPointsPerSecond,
            timeSeconds: animationTimeSeconds
        )

        // 범위를 벗어나지 못하게 clamp
        let clampedOffsetX = clamp(rawOffsetX, min: -maxTravelRange, max: 0)

        // 서브픽셀로 인한 깜빡임/얇은 틈 방지
        let pixelAlignedOffsetX = pixelAligned(clampedOffsetX)

        return Image(backgroundAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: renderWidth, height: viewportHeight, alignment: .leading)
            .offset(x: pixelAlignedOffsetX)
            .frame(width: viewportWidth, height: viewportHeight)
            .clipped()
            .ignoresSafeArea()
    }

    // MARK: - Motion

    private func pingPongHorizontalOffset(
        travelRange: CGFloat,
        speedPointsPerSecond: CGFloat,
        timeSeconds: CGFloat
    ) -> CGFloat {
        guard speedPointsPerSecond > 0, travelRange > 0 else { return 0 }

        let oneWayDurationSeconds = travelRange / speedPointsPerSecond
        let cycleDurationSeconds = oneWayDurationSeconds * 2
        let cycleTimeSeconds = timeSeconds.truncatingRemainder(dividingBy: cycleDurationSeconds)

        if cycleTimeSeconds <= oneWayDurationSeconds {
            let progress = cycleTimeSeconds / oneWayDurationSeconds
            return -travelRange * smoothStep(progress)
        } else {
            let backwardTimeSeconds = cycleTimeSeconds - oneWayDurationSeconds
            let backwardProgress = backwardTimeSeconds / oneWayDurationSeconds
            return -travelRange * (1 - smoothStep(backwardProgress))
        }
    }

    private func smoothStep(_ normalizedValue: CGFloat) -> CGFloat {
        let clampedValue = min(max(normalizedValue, 0), 1)
        return (3 * clampedValue * clampedValue) - (2 * clampedValue * clampedValue * clampedValue)
    }

    private func clamp(_ value: CGFloat, min minimumValue: CGFloat, max maximumValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimumValue), maximumValue)
    }

    private func pixelAligned(_ value: CGFloat) -> CGFloat {
        let screenScale = UIScreen.main.scale
        return (value * screenScale).rounded() / screenScale
    }
}
