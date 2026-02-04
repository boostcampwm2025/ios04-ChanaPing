//
//  NaverMarkerAdapter.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
import NMapsMap

/// NMFMarker를 MarkerProtocol로 감싼 어댑터
public final class NaverMarkerAdapter: MarkerProtocol {

    private let marker: NMFMarker
    private weak var currentMapView: NMFMapView?

    public init(marker: NMFMarker) {
        self.marker = marker
    }

    public var alpha: CGFloat {
        get { marker.alpha }
        set { marker.alpha = newValue }
    }

    public func setIcon(_ image: UIImage) {
        marker.iconImage = NMFOverlayImage(image: image)
    }

    public func setAttached(to mapView: MapViewProtocol?) {
        guard let mapView else {
            marker.mapView = nil
            currentMapView = nil
            return
        }
        guard let naver = mapView as? NaverMapViewAdapter else {
            marker.mapView = nil
            currentMapView = nil
            return
        }
        marker.mapView = naver.mapView
        currentMapView = naver.mapView
    }

    public func setOnTap(_ handler: @escaping () -> Void) {
        marker.touchHandler = { _ in
            handler()
            return true
        }
    }
}
