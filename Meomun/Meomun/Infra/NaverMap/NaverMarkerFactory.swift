//
//  NaverMarkerFactory.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
import NMapsMap

public struct NaverMarkerFactory: MarkerFactoryProtocol {
    public init() {}

    public func makeMarker(coordinate: Coordinate) -> MarkerProtocol {
        let pos = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let marker = NMFMarker(position: pos)
        marker.anchor = CGPoint(x: 0.5, y: 1.0)
        marker.zIndex = 1000
        marker.isFlat = false

        // placeholder: 투명 1px
        marker.iconImage = NaverMarkerPlaceholder.overlayImage
        marker.alpha = 0.0

        return NaverMarkerAdapter(marker: marker)
    }
}
