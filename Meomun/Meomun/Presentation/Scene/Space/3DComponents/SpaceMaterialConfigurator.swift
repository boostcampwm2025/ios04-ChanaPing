//
//  SpaceMaterialConfigurator.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit
import UIKit

struct SpaceMaterialConfigurator {
    func configureDome(domeEntity: Entity, dayPart: DayPart) {
        let gradient = DomeColor.colors(for: dayPart)

        configureShaderMaterial(on: domeEntity, surfaceName: "Dome_01", category: .resource) { material in
            try material.setParameter(name: "topColor", value: .color(gradient.top))
            try material.setParameter(name: "bottomColor", value: .color(gradient.bottom))
        }
    }

    func configureGround(
        domeEntity: Entity,
        dayPart: DayPart
    ) {
        let gradient = DomeColor.colors(for: dayPart)

        configureShaderMaterial(on: domeEntity, surfaceName: "Ground_01", category: .resource) { material in
            try material.setParameter(name: "topColor", value: .color(gradient.top))
            try material.setParameter(name: "bottomColor", value: .color(gradient.bottom))

            try material.setParameter(name: "Density", value: .float(0.6))
            try material.setParameter(name: "Contrast", value: .float(0.2))
            try material.setParameter(name: "TimeSpeed", value: .float(0.3))
        }
    }

}

private extension SpaceMaterialConfigurator {
    private func configureShaderMaterial(
        on parent: Entity,
        surfaceName: String,
        category: LogCategory = .resource,
        configure: (inout ShaderGraphMaterial) throws -> Void
    ) {
        guard let surfaceEntity = parent.findEntity(named: surfaceName) else {
            AppLog.warn(
                "Surface entity '\(surfaceName)' not found",
                category: category
            )
            return
        }

        guard
            let model = surfaceEntity.components[ModelComponent.self],
            var material = model.materials.first as? ShaderGraphMaterial
        else {
            AppLog.warn(
                "ShaderGraphMaterial not found on '\(surfaceName)'",
                category: category
            )
            return
        }

        do {
            try configure(&material)
            surfaceEntity.components[ModelComponent.self]?.materials = [material]
        } catch {
            AppLog.error(
                "Failed to configure material on '\(surfaceName)'",
                category: category,
                error: error
            )
        }
    }
}
