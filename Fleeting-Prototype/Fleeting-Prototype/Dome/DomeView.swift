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

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let anchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anchor)

        Task {
            do {
                let domeEntity = try await loadModelEntity()
                configureDomeTransform(domeEntity)
                anchor.addChild(domeEntity)
            } catch {
                print("Failed to load dome model: \(error)")
            }
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) { }
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
        modelFileExtension: "usdz"
    )
    .ignoresSafeArea()
}
