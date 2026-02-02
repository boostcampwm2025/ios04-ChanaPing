//
//  ClusterMarkerUpdater.swift
//  Meomun
//
//  Created by hoon on 1/27/26.
//

import NMapsMap

final class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    // 원 지름
    private let diameter: CGFloat = 30

    // 캐싱된 아이콘 이미지
    private lazy var cachedIcon: NMFOverlayImage = {
        let image = Self.renderIcon(diameter: diameter)
        return NMFOverlayImage(image: image)
    }()

    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)

        marker.iconImage = cachedIcon
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
                cameraUpdate.animationDuration = 0.5
                mapView.moveCamera(cameraUpdate)
            }

            return true
        }
    }

    private static func renderIcon(
        diameter: CGFloat,
        fillColor: UIColor = .mmTabActive
    ) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            fillColor.setFill()
            path.fill()
        }
    }
}
