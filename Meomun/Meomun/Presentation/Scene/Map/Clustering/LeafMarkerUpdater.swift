//
//  LeafMarkerUpdater.swift
//  Meomun
//
//  Created by hoon on 1/27/26.
//

import NMapsMap
import UIKit

class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)

        let diameter: CGFloat = 28  // 전체 크기
        let iconDiameter: CGFloat = 18  // 내부 아이콘 크기

        let image = Self.renderIconWithBackground(
            diameter: diameter,
            backgroundColor: .white.withAlphaComponent(0.9),
            icon: UIImage.spaceIcon,
            iconDiameter: iconDiameter
        )

        marker.iconImage = NMFOverlayImage(image: image)
        marker.width = diameter
        marker.height = diameter
        marker.touchHandler = { overlay in
            if let mapView = overlay.mapView {
                let position = NMFCameraPosition(
                    info.position,
                    zoom: Double(info.maxZoom + 1),
                    tilt: 45,
                    heading: 0
                )

                let cameraUpdate = NMFCameraUpdate(position: position)
                cameraUpdate.animation = .easeIn
                mapView.moveCamera(cameraUpdate)
            }

            return true
        }
    }

    private static func renderIconWithBackground(
        diameter: CGFloat,
        backgroundColor: UIColor,
        icon: UIImage,
        iconDiameter: CGFloat
    ) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // 배경 원
            let circlePath = UIBezierPath(ovalIn: rect)
            backgroundColor.setFill()
            circlePath.fill()

            // 중앙 아이콘
            let iconRect = CGRect(
                x: (diameter - iconDiameter) / 2,
                y: (diameter - iconDiameter) / 2,
                width: iconDiameter,
                height: iconDiameter
            )

            icon.draw(in: iconRect)
        }
    }
}
