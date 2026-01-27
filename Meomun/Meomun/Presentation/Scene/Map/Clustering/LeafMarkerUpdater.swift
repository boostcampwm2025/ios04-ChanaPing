//
//  LeafMarkerUpdater.swift
//  Meomun
//
//  Created by hoon on 1/27/26.
//

import NMapsMap

class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)

        marker.iconImage = NMFOverlayImage(image: .spaceIcon)
        marker.width = 24
        marker.height = 24
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
}
