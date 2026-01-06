//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import SwiftUI
import RealityKit

struct SpaceView: View {
    // 카메라 회전 상태 관리
    @State private var camera: PerspectiveCamera?
    @State private var yaw: Float = 0  // 수평 회전 (좌우)
    @State private var pitch: Float = 0  // 수직 회전 (상하)

    // 드래그 제스처 상태
    @State private var lastDragValue: CGSize = .zero

    var body: some View {
        RealityView { content in
            // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
            content.camera = .virtual
            configureSpace(content: content)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDrag(value: value)
                }
                .onEnded { _ in
                    lastDragValue = .zero
                }
        )
        .ignoresSafeArea()
    }
}

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        Task {
            do {
                // 1. 배경 돔 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                content.add(domeEntity)
            } catch {
                print("돔 로드 실패: \(error)")
            }

            // 2. 카메라 설정 (돔 중앙에 위치)
            let camera = PerspectiveCamera()

            // 3. 카메라를 돔 중앙(원점)에 배치
            camera.position = [0, 0.7, 0]
            content.add(camera)

            self.camera = camera
        }
    }
}

extension SpaceView {
    private func handleDrag(value: DragGesture.Value) {
        guard let camera else { return }

        // 드래그 변화량 계산
        let deltaX = Float(value.translation.width - lastDragValue.width)
        let deltaY = Float(value.translation.height - lastDragValue.height)

        // 회전 감도 조절을 위한 상수 (값이 클수록 빠르게 회전)
        let sensitivity: Float = 0.003

        // Yaw: 수평 회전 (좌우 드래그)
        yaw += deltaX * sensitivity

        // Pitch: 수직 회전 (상하 드래그) - 제한을 두어 뒤집힘 방지
        pitch += deltaY * sensitivity
        pitch = max(0, min(Float.pi / 2, pitch)) // 0도 ~ 90도 제한

        // 카메라 시야 방향 변경 (위치는 고정, 시야만 변경)
        // Y축 기준 회전(yaw) 후 X축 기준 회전(pitch)
        let yawRotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        let pitchRotation = simd_quatf(angle: pitch, axis: [1, 0, 0])
        camera.orientation = yawRotation * pitchRotation

        lastDragValue = value.translation
    }
}

#Preview {
    SpaceView()
}
