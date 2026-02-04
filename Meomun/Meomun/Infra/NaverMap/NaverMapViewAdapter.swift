//
//  NaverMapViewAdapter.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation
import NMapsMap

/// NMFMapView를 MapViewProtocol로 감싼 어댑터
final class NaverMapViewAdapter: MapViewProtocol {
    let mapView: NMFMapView

    init(_ mapView: NMFMapView) {
        self.mapView = mapView
    }
}
