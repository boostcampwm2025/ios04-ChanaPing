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
                let bubblePlacer = BubblePlacer()
                let bubbleCount = 10

                for _ in 0..<bubbleCount {
                    let bubbleEntity = bubbleFactory.makeBubbleEntity()

                    bubbleEntity.position = bubblePlacer.randomPositionInsideHemisphere(
                        radiusRange: 0.9...1.2,
                        yRange: 0.1...0.9,
                        minimumDistanceFromCenter: 0.9,
                        minimumDistanceFromViewAxis: 0.25,
                        maxAttempts: 60
                    )

                    rotationRootAnchor.addChild(bubbleEntity)
                }
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

// MARK: - BubblePlacer

private struct BubblePlacer {
    func randomPositionInsideHemisphere(
        radiusRange: ClosedRange<Float>,
        yRange: ClosedRange<Float>,
        minimumDistanceFromCenter: Float,
        minimumDistanceFromViewAxis: Float,
        maxAttempts: Int
    ) -> SIMD3<Float> {
        for _ in 0..<maxAttempts {
            let theta = Float.random(in: 0...(2 * .pi))
            let yAxis = Float.random(in: yRange)
            let radius = Float.random(in: radiusRange)

            let xzLimit = max(0.0, sqrt(max(0.0, radius * radius - yAxis * yAxis)))
            let xAxis = cos(theta) * xzLimit
            let zAxis = sin(theta) * xzLimit

            let position = SIMD3<Float>(xAxis, yAxis, zAxis)

            if simd_length(position) < minimumDistanceFromCenter {
                continue
            }

            let distanceFromViewAxis = simd_length(SIMD2<Float>(xAxis, yAxis))

            if distanceFromViewAxis < minimumDistanceFromViewAxis {
                continue
            }

            return position
        }

        return SIMD3<Float>(minimumDistanceFromViewAxis, yRange.upperBound, -radiusRange.upperBound)
    }
}
