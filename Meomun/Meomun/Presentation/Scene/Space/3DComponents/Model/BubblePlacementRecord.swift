//
//  BubblePlacementRecord.swift
//  Meomun
//
//  Created by Hayeon Park on 2/5/26.
//

import RealityKit

struct BubblePlacementRecord: Equatable {
    let messageID: MessageID
    var position: SIMD3<Float>
    var radius: Float
}
