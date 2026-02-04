//
//  ClusterController.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

protocol MarkerClusteringControlling: AnyObject {
    var isClusterMode: Bool { get }

    func bind(mapView: MapViewProtocol)
    func updateModeIfNeeded(zoomLevel: Double)

    func onSnapshotUpdated(
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    )
}

@MainActor
final class MarkerClusterController: MarkerClusteringControlling {

    private let maxZoom: Double
    private let clustererFactory: ClustererFactoryProtocol
    private let itemsBuilder: ClusterItemsBuilding
    private let markerRegistry: MarkerRegistry

    private var clusterer: ClustererProtocol?
    private weak var mapView: MapViewProtocol?

    private(set) var isClusterMode: Bool = false

    private var cachedPlaceStore: [Coordinate: [Message]] = [:]
    private var cachedNoPlaceStore: [Coordinate: [Message]] = [:]

    init(
        maxZoom: Double,
        clustererFactory: ClustererFactoryProtocol,
        itemsBuilder: ClusterItemsBuilding,
        markerRegistry: MarkerRegistry
    ) {
        self.maxZoom = maxZoom
        self.clustererFactory = clustererFactory
        self.itemsBuilder = itemsBuilder
        self.markerRegistry = markerRegistry
    }

    func bind(mapView: MapViewProtocol) {
        self.mapView = mapView
        setupClustererIfNeeded()

        if isClusterMode {
            markerRegistry.detachAll()
            clusterer?.attach(to: mapView)
            syncFromCache()
        }
    }

    func updateModeIfNeeded(zoomLevel: Double) {
        let shouldCluster = zoomLevel <= maxZoom
        guard shouldCluster != isClusterMode else { return }
        guard let mapView else {
            isClusterMode = shouldCluster
            return
        }

        setClusterMode(shouldCluster, mapView: mapView)
    }

    func onSnapshotUpdated(
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) {
        cachedPlaceStore = placeStore
        cachedNoPlaceStore = noPlaceStore

        // 모드면 즉시 반영, 아니면 캐시만 갱신
        guard isClusterMode else { return }
        syncFromCache()
    }

    private func setupClustererIfNeeded() {
        if clusterer == nil {
            clusterer = clustererFactory.makeClusterer()
        }
    }

    private func setClusterMode(_ enabled: Bool, mapView: MapViewProtocol) {
        isClusterMode = enabled

        // 클러스터러가 없으면 sync/addAll/attach가 모두 무의미해지므로 여기서 보장
        setupClustererIfNeeded()

        if enabled {
            // 1) 개별 마커 숨김
            markerRegistry.detachAll()

            // 2) 클러스터러 attach (attach 이후 addAll/clear가 반영되도록 순서 고정)
            clusterer?.attach(to: mapView)

            // 3) 모드 전환 즉시 최신 캐시로 동기화
            syncFromCache()
        } else {
            // 1) 클러스터 숨김
            clusterer?.attach(to: nil)

            // 2) 개별 마커 복원
            markerRegistry.attachAll(to: mapView)
        }
    }

    private func syncFromCache() {
        guard let clusterer, isClusterMode else { return }

        let items = itemsBuilder.build(
            placeStore: cachedPlaceStore,
            noPlaceStore: cachedNoPlaceStore
        )
        clusterer.setItems(items)
    }
}

// swiftlint:disable identifier_name
#if DEBUG
extension MarkerClusterController {
    var debug_isClusterMode: Bool { isClusterMode }
}
#endif
// swiftlint:enable identifier_name
