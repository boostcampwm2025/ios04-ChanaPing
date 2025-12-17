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

                let messages: [String] = [
                    "조용함",
                    "커피 맛있다",
                    "분위기 좋다",
                    "햇살이 좋아",
                    "좌석 편하다",
                    "음악이 좋다",
                    "집중 잘 된다",
                    "향이 좋다",
                    "라떼가 최고",
                    "여유롭다"
                ]

                for index in 0..<messages.count {
                    let bubbleEntity = bubbleFactory.makeBubbleEntity(message: messages[index])

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

    // MARK: - Tuning

    private enum Tuning {
        static let bubbleRadiusRange: ClosedRange<Float> = 0.04...0.10
        static let bubbleScaleRange: ClosedRange<Float> = 0.9...1.2

        static let textInsetRatio: Float = 0.85

        static let textScaleMinimum: Float = 0.20
        static let textScaleMaximum: Float = 2.50

        // Billboard 기준 +Z는 항상 카메라 방향
        static let textForwardOffset: Float = 0.002

        static let fontSize: CGFloat = 0.05
        static let extrusionDepth: Float = 0.001
    }

    // MARK: - Public

    func makeBubbleEntity(message: String) -> Entity {
        let containerEntity = Entity()

        let (bubbleEntity, effectiveBubbleRadius) = makeBubbleSphereAndEffectiveRadius()
        containerEntity.addChild(bubbleEntity)

        // Billboard는 "회전 피벗" 역할만 담당
        let billboardPivotEntity = Entity()
        billboardPivotEntity.components.set(BillboardComponent())
        containerEntity.addChild(billboardPivotEntity)

        let textModelEntity = makeCenteredTextModel(
            message: message,
            maxRadius: effectiveBubbleRadius * Tuning.textInsetRatio
        )

        billboardPivotEntity.addChild(textModelEntity)

        return containerEntity
    }

    // MARK: - Bubble

    private func makeBubbleSphereAndEffectiveRadius() -> (ModelEntity, Float) {
        let baseRadius = Float.random(in: Tuning.bubbleRadiusRange)
        let sphereMesh = MeshResource.generateSphere(radius: baseRadius)

        var material = SimpleMaterial()
        material.color = .init(
            tint: .white.withAlphaComponent(0.25),
            texture: nil
        )
        material.roughness = .float(0.1)
        material.metallic = .float(0.0)

        let bubbleEntity = ModelEntity(mesh: sphereMesh, materials: [material])

        let bubbleScale = Float.random(in: Tuning.bubbleScaleRange)
        bubbleEntity.scale = SIMD3<Float>(repeating: bubbleScale)

        let effectiveRadius = baseRadius * bubbleScale
        return (bubbleEntity, effectiveRadius)
    }

    // MARK: - Text

    private func makeCenteredTextModel(
        message: String,
        maxRadius: Float
    ) -> ModelEntity {

        let textMesh = MeshResource.generateText(
            message,
            extrusionDepth: Tuning.extrusionDepth,
            font: .systemFont(ofSize: Tuning.fontSize, weight: .semibold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        var textMaterial = SimpleMaterial()
        textMaterial.color = .init(
            tint: .white.withAlphaComponent(1.0),
            texture: nil
        )
        textMaterial.roughness = .float(1.0)
        textMaterial.metallic = .float(0.0)

        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

        // 기본 스케일에서 시각적 bounds 측정
        textEntity.scale = SIMD3<Float>(repeating: 1.0)

        let initialBounds = textEntity.visualBounds(relativeTo: nil)
        let initialExtents = initialBounds.extents

        // 회전에 영향받지 않도록 "바운딩 스피어 반지름" 기준 사용
        let textBoundingRadius =
            0.5 * sqrt(
                initialExtents.x * initialExtents.x +
                initialExtents.y * initialExtents.y +
                initialExtents.z * initialExtents.z
            )

        // 버블 반지름에 맞게 자동 스케일
        if textBoundingRadius > 0 {
            let rawScale = maxRadius / textBoundingRadius
            let clampedScale = min(
                max(rawScale, Tuning.textScaleMinimum),
                Tuning.textScaleMaximum
            )
            textEntity.scale = SIMD3<Float>(repeating: clampedScale)
        }

        // 스케일 반영 후 bounds 중심을 기준으로 중앙 정렬
        let scaledBounds = textEntity.visualBounds(relativeTo: nil)
        let scaledCenter = scaledBounds.center

        textEntity.position = SIMD3<Float>(
            -scaledCenter.x,
            -scaledCenter.y,
            -scaledCenter.z + Tuning.textForwardOffset
        )

        return textEntity
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
