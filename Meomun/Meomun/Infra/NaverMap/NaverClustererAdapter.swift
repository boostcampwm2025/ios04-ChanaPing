//
//  NaverClustererAdapter.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation
import NMapsMap

/// NMCClusterer를 ClustererProtocol로 감싼 어댑터
public final class NaverClustererAdapter: ClustererProtocol {

    private let clusterer: NMCClusterer<ItemKey>

    private let leafUpdater: NMCLeafMarkerUpdater
    private let clusterUpdater: NMCClusterMarkerUpdater

    public init(
        leafUpdater: NMCLeafMarkerUpdater,
        clusterUpdater: NMCClusterMarkerUpdater
    ) {
        self.leafUpdater = leafUpdater
        self.clusterUpdater = clusterUpdater

        let builder = NMCBuilder<ItemKey>()
        builder.leafMarkerUpdater = leafUpdater
        builder.clusterMarkerUpdater = clusterUpdater
        self.clusterer = builder.build()
    }

    public func attach(to mapView: MapViewProtocol?) {
        guard let mapView else {
            clusterer.mapView = nil
            return
        }
        guard let naver = mapView as? NaverMapViewAdapter else {
            clusterer.mapView = nil
            return
        }
        clusterer.mapView = naver.mapView
    }

    public func clear() {
        clusterer.clear()
    }

    public func setItems(_ items: [ClusterItem]) {
        var map: [ItemKey: NSObject] = [:]
        map.reserveCapacity(items.count)

        for item in items {
            let pos = NMGLatLng(lat: item.coordinate.latitude, lng: item.coordinate.longitude)
            let key = ItemKey(identifier: item.id, position: pos)
            map[key] = item.tag
        }
        clusterer.addAll(map)
    }
}
