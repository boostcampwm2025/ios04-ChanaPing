//
//  MarkerRegistry.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@MainActor
protocol MarkerAttaching: AnyObject {
    func attach(_ marker: MarkerProtocol, to mapView: MapViewProtocol)
    func detach(_ marker: MarkerProtocol)
}

/// 마커 저장소 + 생명주기(생성/재사용/삭제) + 일괄 attach/detach 만 담당.
/// "언제 attach할지"는 외부(MessageMarkerManager)가 결정.
@MainActor
final class MarkerRegistry {

    private var markers: [MarkerGroupKey: MarkerProtocol] = [:]

    private let markerFactory: MarkerFactoryProtocol
    private weak var attacher: MarkerAttaching?

    init(markerFactory: MarkerFactoryProtocol) {
        self.markerFactory = markerFactory
    }

    func setAttacher(_ attacher: MarkerAttaching) {
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
            attacher?.attach(existing, to: mapView)
            return existing
        }

        let marker = markerFactory.makeMarker(coordinate: coordinate)
        attacher?.attach(marker, to: mapView)

        markers[key] = marker
        return marker
    }

    func remove(key: MarkerGroupKey) {
        guard let marker = markers[key] else { return }

        attacher?.detach(marker)
        markers.removeValue(forKey: key)
    }

    func removeAll() {
        markers.values.forEach { attacher?.detach($0) }
        markers.removeAll()
    }

    func detachAll() {
        markers.values.forEach { attacher?.detach($0) }
    }

    func attachAll(to mapView: MapViewProtocol) {
        markers.values.forEach { attacher?.attach($0, to: mapView) }
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
