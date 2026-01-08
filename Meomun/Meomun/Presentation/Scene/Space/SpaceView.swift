//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

struct SpaceView: View {

    @StateObject private var store = SpaceViewStore()

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
                    rotationCamera.handleDrag(
                        translationX: Float(value.translation.width),
                        translationY: Float(value.translation.height)
                    )
                }
                .onEnded { _ in
                    rotationCamera.endDrag()
                }
        )
        .task {
            await store.send(intent: .onAppear)
        }
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
