//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import SwiftUI
import RealityKit

struct SpaceView: View {
    var body: some View {
        RealityView { content in
            // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
            content.camera = .virtual
            configureSpace(content: content)
        }
        .ignoresSafeArea()
    }
}

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        Task {
            do {
                // 1. 배경 돔 로드
                let domeEntity = try await Entity(named: "Dome.usdz")

                // 2. 돔 앵커에 추가
                let domeAnchor = AnchorEntity(world: .zero)
                domeAnchor.addChild(domeEntity)
                content.add(domeAnchor)
            } catch {
                print("돔 로드 실패: \(error)")
            }

            // 3. 카메라 설정 (돔 중앙에 위치)
            let cameraAnchor = AnchorEntity()
            let camera = PerspectiveCamera()

            // 4. 카메라를 돔 중앙(원점)에 배치
            camera.position = [0, 0.7, 0]
            cameraAnchor.addChild(camera)
            content.add(cameraAnchor)
        }
    }
}

#Preview {
    SpaceView()
}
