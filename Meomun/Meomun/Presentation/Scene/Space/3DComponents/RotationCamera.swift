//
//  RotationCamera.swift
//  Meomun
//
//  Created by MinwooJe on 1/7/26.
//

import RealityKit
import SwiftUI

final class RotationCamera {
    private let camera: PerspectiveCamera

    /// 수평 회전 (좌우)
    private var yaw: Float = 0

    /// 수직 회전 (상하)
    private var pitch: Float = 0

    /// 드래그 추적을 위한 이전 translation 값
    private var lastTranslation: (x: Float, y: Float) = (0, 0)

    /// 회전 감도 조절을 위한 상수 (값이 클수록 빠르게 회전)
    private let sensitivity: Float

    init(
        position: SIMD3<Float>,
        rotateSensitivity: Float
    ) {
        self.camera = PerspectiveCamera()
        self.camera.position = position
        self.sensitivity = rotateSensitivity
    }

    func addToScene(_ content: RealityViewCameraContent) {
        content.add(camera)
    }

    /// 드래그 입력을 처리하여 카메라를 회전시킵니다
    func handleDrag(translationX: Float, translationY: Float) {
        let deltaX = translationX - lastTranslation.x
        let deltaY = translationY - lastTranslation.y

        rotate(deltaX: deltaX, deltaY: deltaY)

        lastTranslation = (translationX, translationY)
    }

    /// 드래그가 끝났을 때 호출합니다
    func endDrag() {
        lastTranslation = (0, 0)
    }

    private func rotate(deltaX: Float, deltaY: Float) {
        yaw += deltaX * sensitivity
        pitch += deltaY * sensitivity

        // 회전 제한을 두어 뒤집힘 방지
        pitch = max(0, min(Float.pi / 2, pitch))    // 0도 ~ 90도 제한

        // 카메라 시야 방향 변경 (위치는 고정, 시야만 변경)
        // Y축 기준 회전(yaw) 후 X축 기준 회전(pitch)
        let yawRotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        let pitchRotation = simd_quatf(angle: pitch, axis: [1, 0, 0])
        camera.orientation = yawRotation * pitchRotation
    }
}
