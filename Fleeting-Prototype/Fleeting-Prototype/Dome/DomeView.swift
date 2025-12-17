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
