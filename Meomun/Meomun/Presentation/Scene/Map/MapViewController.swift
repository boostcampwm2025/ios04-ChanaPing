//
//  MapViewController.swift
//  Meomun
//
//  Created by hoon on 1/6/26.
//

import SwiftUI
import UIKit

import NMapsMap

final class MapViewController: UIViewController {

    // MARK: - Properties

    private var appLifecycleObservers: [NSObjectProtocol] = []

    // MARK: - Animation Properties

    private var bubbleRotationTimer: Timer?
    private let frameInterval: TimeInterval = 1.0 / 60.0
    private let rotationInterval: TimeInterval = 3.0
    private let animationDuration: TimeInterval = 1.0

    // MARK: - Callback

    private let onTapPlace: ((Place) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?
    private let onCameraIdle: ((Coordinate, BoundingBox) -> Void)?
    private let onCameraChangedByLocation: ((Coordinate, BoundingBox) -> Void)?

    // MARK: - Dependencies

    private var locationManager = CLLocationManager()
    private let messageMarkerManager: MessageMarkerManager

    // MARK: - Init

    init(
        messageMarkerManager: MessageMarkerManager,
        onTapPlace: ((Place) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil,
        onCameraIdle: ((Coordinate, BoundingBox) -> Void)? = nil,
        onCameraChangedByLocation: ((Coordinate, BoundingBox) -> Void)? = nil
    ) {
        self.messageMarkerManager = messageMarkerManager
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        self.onCameraIdle = onCameraIdle
        self.onCameraChangedByLocation = onCameraChangedByLocation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.messageMarkerManager = .init(rotationAnimator: .init(), bubbleImageRenderer: .init())
        self.onTapPlace = nil
        self.onTapNoPlace = nil
        self.onCameraIdle = nil
        self.onCameraChangedByLocation = nil
        super.init(coder: coder)
    }

    private let naverMapView: NMFNaverMapView = {
        let naverMapView = NMFNaverMapView()

        // 지도 UI 설정
        naverMapView.showCompass = false
        naverMapView.showScaleBar = false
        naverMapView.showZoomControls = false
        naverMapView.showLocationButton = true
        naverMapView.mapView.logoInteractionEnabled = true  // Naver Map 정책상 켜야 함.

        // 최소 및 최대 줌 레벨 설정
        naverMapView.mapView.minZoomLevel = 8
        naverMapView.mapView.maxZoomLevel = 18

        // 지도 스타일
        naverMapView.mapView.customStyleId = "bf0bd9ae-f750-4895-8246-2744297005d0"

        // 초기 카메라
        let camera = NMFCameraPosition(
            NMGLatLng(lat: 37.5665, lng: 126.9780),
            zoom: 17,
            tilt: 45,
            heading: 0
        )

        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: camera))

        return naverMapView
    }()

    private let tabBarHeight: CGFloat = 96

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureLayout()

        naverMapView.mapView.contentInset = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: tabBarHeight - 20,
            right: 24
        )

        // 카메라 delegate 등록
        naverMapView.mapView.addCameraDelegate(delegate: self)

        // 앱 라이프사이클 옵저버 등록
        registerAppLifecycleObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startBubbleRotationTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopBubbleRotationTimer()
    }

    deinit {
        unregisterAppLifecycleObservers()
        stopBubbleRotationTimer()
        naverMapView.mapView.removeCameraDelegate(delegate: self)
    }
}

// MARK: - Register Observers

extension MapViewController {
    private func registerAppLifecycleObservers() {
        // 이미 있으면 중복 등록 방지
        unregisterAppLifecycleObservers()

        let center = NotificationCenter.default

        appLifecycleObservers.append(
            center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.stopBubbleRotationTimer()
            }
        )

        appLifecycleObservers.append(
            center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // 화면이 아직 보이는 상태면 다시 시작
                guard let self else { return }
                if self.view.window != nil {
                    self.startBubbleRotationTimer()
                }
            }
        )
    }

    private func unregisterAppLifecycleObservers() {
        let center = NotificationCenter.default
        appLifecycleObservers.forEach { center.removeObserver($0) }
        appLifecycleObservers.removeAll()
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

// MARK: - UserLocation

extension MapViewController {
    func updateUserLocation(_ coordinate: Coordinate?) {
        guard let coordinate else { return }

        naverMapView.mapView.positionMode = .direction

        let latLng = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: latLng)
        cameraUpdate.animation = .easeIn
        naverMapView.mapView.moveCamera(cameraUpdate)
    }
}

// MARK: - Camera Moving

extension MapViewController {
    func moveCamera(to coordinate: Coordinate, zoom: Double? = nil) {
        let latLng = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let update = NMFCameraUpdate(scrollTo: latLng)

        update.animation = .easeIn
        update.animationDuration = 0.35

        guard let zoom else {
            naverMapView.mapView.moveCamera(update)
            return
        }

        let position = NMFCameraPosition(
            latLng,
            zoom: zoom,
            tilt: 45,
            heading: 0
        )
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
    }
}

// MARK: - Messages

extension MapViewController {
    /// 메시지 배열로 마커를 로딩합니다.
    func loadMessages(_ messages: [Message]) {
        messageMarkerManager.loadMessages(
            messages,
            mapView: naverMapView.mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
    }
}

// MARK: - Animation Timer

extension MapViewController {
    private func startBubbleRotationTimer() {
        bubbleRotationTimer?.invalidate()

        bubbleRotationTimer = Timer.scheduledTimer(
            withTimeInterval: frameInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.messageMarkerManager.updateAnimations()
            }
        }

        if let timer = bubbleRotationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopBubbleRotationTimer() {
        bubbleRotationTimer?.invalidate()
        bubbleRotationTimer = nil
    }
}

// MARK: - NMFMapViewCameraDelegate

extension MapViewController: NMFMapViewCameraDelegate {
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let center = mapView.cameraPosition.target
        let coordinate = Coordinate(latitude: center.lat, longitude: center.lng)
        let domainBounds = makeBoundingBox(from: mapView)

        onCameraIdle?(coordinate, domainBounds)
        messageMarkerManager.updateClusterModeIfNeeded(zoomLevel: mapView.zoomLevel)
    }

    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        // 위치 추적으로 인한 카메라 변경인지 확인
        guard reason == NMFMapChangedByLocation else { return }

        // 위치 모드가 direction 또는 compass인지 확인
        let positionMode = naverMapView.mapView.positionMode
        guard positionMode == .direction || positionMode == .compass else { return }

        // 카메라 중심 좌표 추출 및 콜백 호출
        let center = mapView.cameraPosition.target
        let coordinate = Coordinate(latitude: center.lat, longitude: center.lng)
        let domainBounds = makeBoundingBox(from: mapView)

        onCameraChangedByLocation?(coordinate, domainBounds)
        messageMarkerManager.updateClusterModeIfNeeded(zoomLevel: mapView.zoomLevel)
    }

    private func makeBoundingBox(from mapView: NMFMapView) -> BoundingBox {
        let nmfBounds = mapView.contentBounds
        return BoundingBox(
            minLatitude: nmfBounds.southWestLat,
            maxLatitude: nmfBounds.northEastLat,
            minLongitude: nmfBounds.southWestLng,
            maxLongitude: nmfBounds.northEastLng
        )
    }
}

// MARK: - MapViewWrapper

struct MapViewWrapper: UIViewControllerRepresentable {
    private let messages: [Message]
    private let userLocation: Coordinate?
    private let cameraMoveTarget: Coordinate?
    private let onCameraMoveConsumed: () -> Void
    private let onTapPlace: ((Place) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?
    private let onCameraIdle: ((Coordinate, BoundingBox) -> Void)?
    private let onCameraChangedByLocation: ((Coordinate, BoundingBox) -> Void)?

    private let messageMarkerManager: MessageMarkerManager

    init(
        userLocation: Coordinate?,
        markerManager: MessageMarkerManager,
        messages: [Message],
        cameraMoveTarget: Coordinate?,
        onCameraMoveConsumed: @escaping () -> Void,
        onTapPlace: ((Place) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil,
        onCameraIdle: ((Coordinate, BoundingBox) -> Void)? = nil,
        onCameraChangedByLocation: ((Coordinate, BoundingBox) -> Void)? = nil
    ) {
        self.userLocation = userLocation
        self.messageMarkerManager = markerManager
        self.messages = messages
        self.cameraMoveTarget = cameraMoveTarget
        self.onCameraMoveConsumed = onCameraMoveConsumed
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        self.onCameraIdle = onCameraIdle
        self.onCameraChangedByLocation = onCameraChangedByLocation
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastMessagesSnapshot: Int?
        var lastCameraMoveTarget: Coordinate?
        var didInitialLoad = false
    }

    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController(
            messageMarkerManager: messageMarkerManager,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace,
            onCameraIdle: onCameraIdle,
            onCameraChangedByLocation: onCameraChangedByLocation
        )

        // 초기 1회 loadMessages() 호출
        viewController.loadMessages(messages)
        viewController.updateUserLocation(userLocation)

        context.coordinator.lastMessagesSnapshot = messagesSnapshot(messages)
        context.coordinator.didInitialLoad = true

        return viewController
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        if let target = cameraMoveTarget {
            // 동일 target인 경우 호출 X
            if context.coordinator.lastCameraMoveTarget?.latitude != target.latitude ||
                context.coordinator.lastCameraMoveTarget?.longitude != target.longitude {

                context.coordinator.lastCameraMoveTarget = target
                uiViewController.moveCamera(
                    to: target,
                    zoom: 17
                )

                DispatchQueue.main.async {
                    onCameraMoveConsumed()
                }
            }
        }

        let snap = messagesSnapshot(messages)

        // 동일 메시지인 경우 loadMessages() 호출 X
        guard context.coordinator.lastMessagesSnapshot != snap else { return }

        context.coordinator.lastMessagesSnapshot = snap
        uiViewController.loadMessages(messages)
    }

    private func messagesSnapshot(_ messages: [Message]) -> Int {
        var hasher = Hasher()

        for message in messages {
            hasher.combine(message.id)
        }

        return hasher.finalize()
    }
}
