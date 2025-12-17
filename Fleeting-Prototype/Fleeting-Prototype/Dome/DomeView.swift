//
//  DomeView.swift
//  Fleeting-Prototype
//
//  Created by Daehoon Lee on 12/18/25.
//

import ARKit
import RealityKit
import SwiftUI

struct DomeView: UIViewRepresentable {
    let modelFileName: String
    let modelFileExtension: String
    let dragDelta: Float

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let rotationRootAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(rotationRootAnchor)
        context.coordinator.rotationRootAnchor = rotationRootAnchor

        Task {
            do {
                let domeEntity = try await loadModelEntity()
                configureDomeTransform(domeEntity)
                rotationRootAnchor.addChild(domeEntity)

                let bubbleFactory = BubbleFactory()
                let bubbleEntity = bubbleFactory.makeBubbleEntity()
                bubbleEntity.position = SIMD3<Float>(0.6, 0.4, -0.9)
                rotationRootAnchor.addChild(bubbleEntity)
            } catch {
                print("Failed to load dome model: \(error)")
            }
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateYawRotation(delta: dragDelta)
    }

    // MARK: - Coordinator

    final class Coordinator {
        var rotationRootAnchor: AnchorEntity?

        private var accumulatedYaw: Float = 0

        func updateYawRotation(delta: Float) {
            guard let rotationRootAnchor else { return }
            guard delta != 0 else { return }

            accumulatedYaw += delta

            rotationRootAnchor.transform.rotation = simd_quatf(
                angle: accumulatedYaw,
                axis: SIMD3<Float>(0, 1, 0)
            )
        }
    }
}

private extension DomeView {
    func loadModelEntity() async throws -> Entity {
        let fileNameWithExtension = "\(modelFileName).\(modelFileExtension)"
        return try await Entity(named: fileNameWithExtension)
    }

    func configureDomeTransform(_ domeEntity: Entity) {
        domeEntity.scale = SIMD3<Float>(repeating: 1.0)
        domeEntity.position = SIMD3<Float>(0, -0.7, 0)
    }
}

#Preview {
    DomeView(
        modelFileName: "Dome",
        modelFileExtension: "usdz",
        dragDelta: 0
    )
    .ignoresSafeArea()
}

// MARK: - BubbleFactory

private struct BubbleFactory {
    func makeBubbleEntity() -> ModelEntity {
        let radius = Float.random(in: 0.04...0.10)
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = SimpleMaterial()

        material.color = .init(
            tint: .white.withAlphaComponent(0.25),
            texture: nil
        )
        material.roughness = .float(0.1)
        material.metallic = .float(0.0)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        let scale = Float.random(in: 0.9...1.2)
        entity.scale = SIMD3<Float>(repeating: scale)

        return entity
    }
}
