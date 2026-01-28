//
//  MiniMapViewController.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import UIKit
import NMapsMap

final class MiniMapViewController: UIViewController {
    // MARK: - Init
    private let miniMapView: NMFMapView = {
        let miniMapView = NMFMapView()

        // 지도 UI 설정
        miniMapView.logoInteractionEnabled = false

        // 유저 상호작용
        // miniMapView.isUserInteractionEnabled = false

        // 최소 및 최대 줌 레벨 설정
        miniMapView.minZoomLevel = 5
        miniMapView.maxZoomLevel = 18

        miniMapView.customStyleId = "bf0bd9ae-f750-4895-8246-2744297005d0"

        return miniMapView
    }()

    private var markers: [NMFMarker] = []
    private var pathOverlay: NMFPath?
    private var pendingMessages: [Message] = []
    private var didApplyOnce = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyIfPossible()
    }
}

// MARK: - Configure UI

extension MiniMapViewController {
    private func configureSubviews() {
        view.addSubview(miniMapView)
        miniMapView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            miniMapView.topAnchor.constraint(equalTo: view.topAnchor),
            miniMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Route Overlay
extension MiniMapViewController {
    func render(messages: [Message]) {
        pendingMessages = messages
        applyIfPossible()
    }

    private func applyIfPossible() {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }
        guard miniMapView.bounds.width > 0, miniMapView.bounds.height > 0 else { return }

        guard !didApplyOnce else { return }
        didApplyOnce = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.apply(messages: self.pendingMessages)
        }
    }

    private func apply(messages: [Message]) {
        clearOverlays()

        let record = buildPaths(messages: messages)
        addMarkers(positions: record.positions, dayLabels: record.dayLabels)

        if record.positions.count >= 2 {
            addPath(positions: record.positions)
        }

        fitCamera(messages: messages, positions: record.positions)
    }

    private func clearOverlays() {
        // 마커 삭제
        markers.forEach { $0.mapView = nil }
        markers.removeAll()

        // 경로선 삭제
        pathOverlay?.mapView = nil
        pathOverlay = nil
    }

    func buildPaths(messages: [Message], calendar: Calendar = .current) -> PathMarkerModel {
        let sortedMessages = messages.sorted { $0.createdAt < $1.createdAt }

        let positions = sortedMessages.map {
            NMGLatLng(
                lat: $0.coordinate.latitude,
                lng: $0.coordinate.longitude
            )
        }
        let dayLabels = sortedMessages.map { "\(calendar.component(.day, from: $0.createdAt))" }

        return PathMarkerModel(positions: positions, dayLabels: dayLabels)
    }

    private func addMarkers(positions: [NMGLatLng], dayLabels: [String]) {
        for (index, position) in positions.enumerated() {
            let marker = NMFMarker(position: position)

            marker.iconImage = MarkerAssets.pin
            marker.iconTintColor = .tabActive
            marker.angle = CGFloat(Int.random(in: 0...15))

            marker.captionText = dayLabels[safe: index] ?? ""
            marker.captionTextSize = 14
            marker.captionHaloColor = .white

            marker.isHideCollidedMarkers = true
            marker.mapView = miniMapView

            markers.append(marker)
        }
    }

    private func addPath(positions: [NMGLatLng]) {
        guard let polyline = NMFPolylineOverlay(positions) else { return }

        polyline.width = 2
        polyline.color = UIColor.tabActive
        polyline.pattern = [6, 3]
        polyline.capType = .round
        polyline.joinType = .round
        polyline.mapView = miniMapView
    }

    private func fitCamera(messages: [Message], positions: [NMGLatLng]) {
        guard let firstPosition = positions.first else { return }

        // Case 1. 메시지 1개 → 고정 확대
        if messages.count == 1 {
            let zoom = miniMapView.maxZoomLevel
            let update = NMFCameraUpdate(
                scrollTo: firstPosition,
                zoomTo: zoom
            )
            miniMapView.moveCamera(update)
            return
        }

        // Case 2. 여러개 있다면 카메라 조정
        var south = firstPosition.lat
        var north = firstPosition.lat
        var west = firstPosition.lng
        var east = firstPosition.lng

        for point in positions {
            south = min(south, point.lat)
            north = max(north, point.lat)
            west = min(west, point.lng)
            east = max(east, point.lng)
        }

        let bounds = NMGLatLngBounds(
            southWest: NMGLatLng(lat: south, lng: west),
            northEast: NMGLatLng(lat: north, lng: east)
        )

        let update = NMFCameraUpdate(fit: bounds, padding: 40)
        miniMapView.moveCamera(update)
    }
}

// MARK: - Marker Distance Helper
extension MiniMapViewController {
    private func maxPairDistanceMeters(from messages: [Message]) -> Double {
        guard messages.count >= 2 else { return 0 }

        var maxDistance: Double = 0

        for i in 0..<(messages.count - 1) {
            let target = messages[i].coordinate
            for j in (i + 1)..<messages.count {
                let compare = messages[j].coordinate
                let distance = target.distance(to: compare)
                maxDistance = max(maxDistance, distance)
            }
        }

        return maxDistance
    }
}
