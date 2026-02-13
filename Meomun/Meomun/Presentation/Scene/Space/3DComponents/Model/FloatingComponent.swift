//
//  FloatingComponent.swift
//  Meomun
//
//  Created by 송지연 on 2/13/26.
//

import RealityKit

struct FloatingComponent: Component {
    var baseY: Float
    var amplitude: Float      // 부유 높이
    var frequency: Float      // 속도
    var phase: Float          // 시작 위상(엔티티마다 다르게)
    var yawAmplitude: Float   // 좌우 흔들림(회전)
}
