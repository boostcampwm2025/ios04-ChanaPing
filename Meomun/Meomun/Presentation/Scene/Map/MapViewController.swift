//
//  MapViewController.swift
//  Meomun
//
//  Created by hoon on 1/6/26.
//

import NMapsMap
import SwiftUI
import UIKit

final class MapViewController: UIViewController {

    private var locationManager = CLLocationManager()
    private var didMoveToCurrentLocation = false

    private var messageMarkers: [UUID: NMFMarker] = [:]

    private let naverMapView: NMFNaverMapView = {
        let naverMapView = NMFNaverMapView()

        // 지도 UI 설정
        naverMapView.showCompass = false
        naverMapView.showScaleBar = false
        naverMapView.showZoomControls = false
        naverMapView.showLocationButton = true

        // 지도 스타일
        naverMapView.mapView.customStyleId = "bf0bd9ae-f750-4895-8246-2744297005d0"

        // 초기 카메라
        let camera = NMFCameraPosition(
            NMGLatLng(lat: 37.5665, lng: 126.9780),
            zoom: 16,
            tilt: 45,
            heading: 0
        )

        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: camera))

        return naverMapView
    }()

    private let tabBarHeight: CGFloat = 96

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLocationManager()
        configureSubviews()
        configureLayout()
        requestLocationAuthorizationIfNeeded()

        naverMapView.mapView.contentInset = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: tabBarHeight - 20,
            right: 24
        )
    }
}

// MARK: - Configure UI

extension MapViewController {
    private func configureSubviews() {
        view.addSubview(naverMapView)
        naverMapView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            naverMapView.topAnchor.constraint(equalTo: view.topAnchor),
            naverMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            naverMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            naverMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

//MARK: - messages

extension MapViewController {
    func updateMessages(_ messages: [Message]) {
        let ids = Set(messages.map(\.id))

        // 1) 사라진 메시지 마커 제거
        for (id, marker) in messageMarkers where !ids.contains(id) {
            marker.mapView = nil
            messageMarkers.removeValue(forKey: id)
        }

        // 2) 메시지 마커 생성 및 업데이트
        for message in messages {
            let marker: NMFMarker

            if let existing = messageMarkers[message.id] {
                marker = existing
            } else {
                marker = NMFMarker()
                messageMarkers[message.id] = marker
            }

            marker.position = NMGLatLng(
                lat: message.coordinate.latitude,
                lng: message.coordinate.longitude
            )

            marker.iconImage = NMFOverlayImage(image: renderBubbleImage(for: message))
            marker.anchor = CGPoint(x: 0.5, y: 1.0)
            marker.zIndex = 1000
            marker.isFlat = false
            marker.mapView = naverMapView.mapView
        }
    }

    private func renderBubbleImage(
        for message: Message,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let bubble = MessageBubble(
            text: message.content,
            placeName: message.placeTag?.name,
            isRecent: message.isRecent(),
            showsAccentLine: true
        )

        let renderer = ImageRenderer(content: bubble)
        renderer.scale = scale
        renderer.isOpaque = false

        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func requestLocationAuthorizationIfNeeded() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocationIfNeeded()
        case .denied, .restricted:
            print("위치 권한이 거부/제한되어 있어 현재 위치로 이동할 수 없습니다.")
        @unknown default:
            break
        }
    }

    private func startUpdatingLocationIfNeeded() {
        locationManager.startUpdatingLocation()
        naverMapView.mapView.positionMode = .direction
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocationAuthorizationIfNeeded()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard didMoveToCurrentLocation == false else { return }

        didMoveToCurrentLocation = true

        let latLng = NMGLatLng(
            lat: currentLocation.coordinate.latitude,
            lng: currentLocation.coordinate.longitude
        )

        // 현재 위치로 카메라 이동
        let cameraUpdate = NMFCameraUpdate(scrollTo: latLng)
        cameraUpdate.animation = .easeIn
        naverMapView.mapView.moveCamera(cameraUpdate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 업데이트 실패: \(error)")
    }
}

// MARK: - MapViewWrapper

struct MapViewWrapper: UIViewControllerRepresentable {
    let messages: [Message]

    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.updateMessages(messages)
        return viewController
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        uiViewController.updateMessages(messages)
    }
}
