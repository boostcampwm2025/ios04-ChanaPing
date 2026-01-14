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
                MessageComposerView()
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
                configureDomeSurface(domeEntity: domeEntity)

                // 2. 카메라 추가
                rotationCamera.addToScene(content)
            } catch {
                AppLog.error(
                    "Failed to load dome entity",
                    category: .space,
                    error: error
                )
            }
        }
    }

    private func configureDomeSurface(domeEntity: Entity) {
        guard let surfaceEntity = domeEntity.findEntity(named: "Dome_01") else {
            AppLog.warn(
                "Dome surface entity 'Dome_01' not found",
                category: .resource
            )
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
                AppLog.error(
                    "Failed to configure dome material",
                    category: .resource,
                    error: error
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpaceView(environment: .init(weather: .sunny, dayPart: .afternoon))
    }
}
