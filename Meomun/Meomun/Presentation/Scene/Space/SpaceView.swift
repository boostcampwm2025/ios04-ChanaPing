//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

struct SpaceView: View {

    // 드래그 제스처 상태
    @State private var lastDragValue: CGSize = .zero

    private let rotationCamera = RotationCamera(
        position: .init(x: 0, y: 0.7, z: 0),
        rotateSensitivity: 0.003
    )

    var body: some View {
        RealityView { content in
            // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
            content.camera = .virtual
            configureSpace(content: content)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 드래그 변화량 계산
                    let deltaX = Float(value.translation.width - lastDragValue.width)
                    let deltaY = Float(value.translation.height - lastDragValue.height)
                    rotationCamera.rotate(deltaX: deltaX, deltaY: deltaY)
                    lastDragValue = value.translation
                }
                .onEnded { _ in
                    lastDragValue = .zero
                }
        )
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                MessageComposeView()
            } label: {
                WriteButton { }
                    .disabled(true)
            }
        }
    }
}

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        Task {
            do {
                // 1. 배경 돔 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                content.add(domeEntity)

                // 2. 카메라 추가
                rotationCamera.addToScene(content)
            } catch {
                print("돔 로드 실패: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpaceView()
    }
}
