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
    @State private var domeEnvironment: DomeEnvironment
    @State private var spaceRootEntity: Entity?
    @State private var didAddMessageBubbles = false

    private let rotationCamera = RotationCamera(
        position: .init(x: 0, y: 0.7, z: 0),
        rotateSensitivity: 0.003
    )

    init(environment: DomeEnvironment) {
        self.domeEnvironment = environment
    }

    var body: some View {
        RealityView { content in
            // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
            content.camera = .virtual
            configureSpace(content: content)
        } update: { _ in
            // messages 로드 완료 + 루트 준비 + 아직 생성 전 => 생성
            guard didAddMessageBubbles == false else { return }
            guard let root = spaceRootEntity else { return }
            guard store.state.messages.isEmpty == false else { return }

            addMessageBubbles(to: root, messages: store.state.messages)

            Task { @MainActor in
                didAddMessageBubbles = true
            }
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

// MARK: - Dome UI

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        guard spaceRootEntity == nil else { return }

        Task {
            do {
                // 0) SpaceRoot 생성 + 보관
                let root = Entity()
                root.name = "SpaceRoot"
                content.add(root)

                await MainActor.run {
                    spaceRootEntity = root
                }

                // 1. 배경 돔 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                domeEntity.name = "Dome"
                root.addChild(domeEntity)
                configureDomeSurface(domeEntity: domeEntity)

                // 2. 카메라 추가
                rotationCamera.addToScene(content)
            } catch {
                print("돔 로드 실패: \(error)")
            }
        }
    }

    private func configureDomeSurface(domeEntity: Entity) {
        guard let surfaceEntity = domeEntity.findEntity(named: "Dome_01") else {
            print("Dome_01을 찾을 수 없음")
            return
        }

        if var material = surfaceEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
            let gradientPair = DomeColor.colors(for: domeEnvironment.dayPart)

            do {
                try material.setParameter(
                    name: "topColor",
                    value: .color(gradientPair.top)
                )

                try material.setParameter(
                    name: "bottomColor",
                    value: .color(gradientPair.bottom)
                )

                surfaceEntity.components[ModelComponent.self]?.materials = [material]
            } catch {
                print("material을 찾을 수 없음: \(error)")
            }
        }
    }
}

// MARK: - Message Bubble UI

extension SpaceView {
    private func addMessageBubbles(to root: Entity, messages: [SpaceMessage]) {
        for message in messages {
            let marker = ModelEntity(
                mesh: .generateSphere(radius: 0.05),
                materials: [SimpleMaterial(color: .white.withAlphaComponent(0.6), isMetallic: false)]
            )

            // 한 곳에 메시지 버블 배치
            marker.name = "MessageBubble-\(message.id.uuidString)"
            marker.position = SIMD3<Float>(0, 0.5, -1.0)

            root.addChild(marker)
        }
    }
}

#Preview {
    NavigationStack {
        SpaceView(environment: .init(weather: .sunny, dayPart: .afternoon))
    }
}
