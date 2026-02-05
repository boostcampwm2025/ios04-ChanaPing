//
//  BubbleCollisionRadiusCalculator.swift
//  Meomun
//
//  Created by Hayeon Park on 2/5/26.
//

import RealityKit

enum BubbleCollisionRadiusCalculator {
    static func radius(fromBoxSize boxSize: SIMD3<Float>, safetyMultiplier: Float = 1.05) -> Float {
        // box half diagonal
        let halfDiagonal = simd_length(boxSize) * 0.5
        return halfDiagonal * safetyMultiplier
    }
}
