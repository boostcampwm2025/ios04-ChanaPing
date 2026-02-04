//
//  MarkerRegistry.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@MainActor
protocol MarkerAttaching {
    func attach(_ marker: MarkerProtocol, to mapView: MapViewProtocol)
    func detach(_ marker: MarkerProtocol)
}

/// markers 딕셔너리의 소유권 + 마커 생성/재사용/삭제/일괄 attach/detach 책임만 담당.
/// - 클러스터 모드 정책(isClusterMode)은 밖에서 주입(MarkerAttaching)으로 통제.
@MainActor
final class MarkerRegistry {

    private var markers: [MarkerGroupKey: MarkerProtocol] = [:]

    private let markerFactory: MarkerFactoryProtocol
    private let attacher: MarkerAttaching

    init(
        markerFactory: MarkerFactoryProtocol,
        attacher: MarkerAttaching
    ) {
        self.markerFactory = markerFactory
        self.attacher = attacher
    }

    var allKeys: Set<MarkerGroupKey> {
        Set(markers.keys)
    }

    func marker(for key: MarkerGroupKey) -> MarkerProtocol? {
        markers[key]
    }

    func currentMarker(for key: MarkerGroupKey) -> MarkerProtocol? {
        markers[key]
    }

    @discardableResult
    func getOrCreate(
        key: MarkerGroupKey,
        coordinate: Coordinate,
        mapView: MapViewProtocol
    ) -> MarkerProtocol {
        if let existing = markers[key] {
            return existing
        }

        let marker = markerFactory.makeMarker(coordinate: coordinate)
        markers[key] = marker

        attacher.attach(marker, to: mapView)
        return marker
    }

    func remove(key: MarkerGroupKey) {
        guard let marker = markers[key] else { return }

        attacher.detach(marker)
        markers.removeValue(forKey: key)
    }

    func removeAll() {
        for (_, marker) in markers {
            attacher.detach(marker)
        }

        markers.removeAll()
    }

    func detachAll() {
        for (_, marker) in markers {
            attacher.detach(marker)
        }
    }

    func attachAll(to mapView: MapViewProtocol) {
        for (_, marker) in markers {
            attacher.attach(marker, to: mapView)
        }
    }
}

// swiftlint:disable identifier_name
#if DEBUG
@MainActor
extension MarkerRegistry {
    var debug_markerCount: Int { markers.count }
}
#endif
// swiftlint:enable identifier_name
