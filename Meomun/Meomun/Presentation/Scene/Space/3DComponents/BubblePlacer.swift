//
//  BubblePlacer.swift
//  Meomun
//
//  Created by Hayeon Park on 1/28/26.
//

import Foundation
import RealityKit

struct BubblePlacer {
    func randomPositionInsideHemisphere(
        radiusRange: ClosedRange<Float>,
        yRange: ClosedRange<Float>,
        minimumDistanceFromCenter: Float,
        minimumDistanceFromViewAxis: Float,
        maxAttempts: Int
    ) -> SIMD3<Float> {
        for _ in 0..<maxAttempts {
            let theta = Float.random(in: 0...(2 * .pi)) // 수평 회전 각도 (0~360도)
            let y = Float.random(in: yRange)            // 높이 범위 (바닥에 너무 붙지 않도록 yRange로 제한)
            let radius = Float.random(in: radiusRange)  // 중심에서 떨어지는 거리 (돔 내부에서 "멀리/가까이" 범위)

            let xzLimit = max(0.0, sqrt(max(0.0, radius * radius - y * y)))
            let x = cos(theta) * xzLimit
            let z = sin(theta) * xzLimit

            let position = SIMD3<Float>(x, y, z)

            // 중심 근처 피하기
            if simd_length(position) < minimumDistanceFromCenter {
                continue
            }

            // 뷰 축(카메라 방향 축) 근처 피하기
            let distanceFromViewAxis = simd_length(SIMD2<Float>(x, y))
            if distanceFromViewAxis < minimumDistanceFromViewAxis {
                continue
            }

            return position
        }

        // 실패 시 fallback
        return SIMD3<Float>(minimumDistanceFromViewAxis, yRange.upperBound, -radiusRange.upperBound)
    }
}
