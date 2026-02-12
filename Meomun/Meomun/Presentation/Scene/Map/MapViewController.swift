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
    private var isFollowingUser: Bool = true
    private var tileCoverHelper: NMFTileCoverHelper?

    // MARK: - Animation Properties

    private var bubbleRotationTimer: Timer?
    private let frameInterval: TimeInterval = 1.0 / 60.0
    private let rotationInterval: TimeInterval = 3.0
    private let animationDuration: TimeInterval = 1.0

    // MARK: - Callback

    private let onTapPlace: (([Message]) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?
    private let onUserGesture: (() -> Void)?
    private let onFollowRequested: (() -> Void)?
    private let onCameraIdle: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)?
    private let onCameraChangedByLocation: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)?
    var onFirstMapIdle: (() -> Void)?
    private var didNotifyFirstMapIdle: Bool = false

    // MARK: - Dependencies

    private let messageMarkerManager: MessageMarkerManager
    private lazy var mapViewAdapter: MapViewProtocol = NaverMapViewAdapter(naverMapView.mapView)

    // MARK: - Init

    init(
        messageMarkerManager: MessageMarkerManager,
        onTapPlace: (([Message]) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil,
        onUserGesture: (() -> Void)?,
        onFollowRequested: (() -> Void)?,
        onCameraIdle: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)? = nil,
        onCameraChangedByLocation: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)? = nil
    ) {
        self.messageMarkerManager = messageMarkerManager
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        self.onUserGesture = onUserGesture
        self.onFollowRequested = onFollowRequested
        self.onCameraIdle = onCameraIdle
        self.onCameraChangedByLocation = onCameraChangedByLocation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.messageMarkerManager = .init(
            markerFactory: NaverMarkerFactory(),
            clustererFactory: NaverClustererFactory(
                leaf: LeafMarkerUpdater(),
                cluster: ClusterMarkerUpdater()
            ),
            rotationAnimator: MessageRotationAnimator(),
            bubbleImageRenderer: BubbleImageRenderer()
        )
        self.onTapPlace = nil
        self.onTapNoPlace = nil
        self.onUserGesture = nil
        self.onFollowRequested = nil
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
        naverMapView.mapView.logoInteractionEnabled = false

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

        // 타일 커버 헬퍼 등록 (타일 변경 시 fetch 트리거)
        let tileCoverHelper = NMFTileCoverHelper(naverMapView.mapView)
        tileCoverHelper.delegate = self
        self.tileCoverHelper = tileCoverHelper

        // 앱 라이프사이클 옵저버 등록
        registerAppLifecycleObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        messageMarkerManager.onViewWillAppear(
            mapView: mapViewAdapter,
            zoomLevel: naverMapView.mapView.zoomLevel
        )

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
    func setFollowingUser(_ isFollowing: Bool) {
        self.isFollowingUser = isFollowing

        if !isFollowing {
            if naverMapView.mapView.positionMode != .normal {
                naverMapView.mapView.positionMode = .normal
            }
        }
    }

    func updateUserLocation(_ coordinate: Coordinate?) {
        guard let coordinate else { return }
        updateUserLocationOverlayOnly(coordinate)

        if isFollowingUser, naverMapView.mapView.positionMode != .direction {
            naverMapView.mapView.positionMode = .direction
        }
    }

    func updateUserLocationOverlayOnly(_ coordinate: Coordinate?) {
        guard let coordinate else { return }

        let latLng = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)

        let overlay = naverMapView.mapView.locationOverlay
        overlay.hidden = false
        overlay.location = latLng
    }
}

// MARK: - Camera Moving

extension MapViewController {
    func moveCamera(to snapshot: MapCameraSnapshot, animated: Bool) {
        naverMapView.mapView.positionMode = .disabled

        let latLng = NMGLatLng(lat: snapshot.coordinate.latitude, lng: snapshot.coordinate.longitude)

        let position = NMFCameraPosition(
            latLng,
            zoom: snapshot.zoom,
            tilt: snapshot.tilt,
            heading: snapshot.heading
        )

        let update = NMFCameraUpdate(position: position)

        if animated {
            update.animation = .fly
            update.animationDuration = 0.75
        } else {
            update.animation = .none
        }

        naverMapView.mapView.moveCamera(update)
    }

    private func currentSnapshot(from mapView: NMFMapView) -> MapCameraSnapshot {
        let position = mapView.cameraPosition
        return MapCameraSnapshot(
            coordinate: .init(
                latitude: position.target.lat,
                longitude: position.target.lng
            ),
            zoom: position.zoom,
            tilt: position.tilt,
            heading: position.heading
        )
    }

    func setTiltEnabled(_ enabled: Bool, animated: Bool = true) {
        let mapView = naverMapView.mapView
        let current = mapView.cameraPosition

        let targetTilt: Double = enabled ? 45.0 : 0.0

        if abs(current.tilt - targetTilt) < 0.1 { return }

        let newPosition = NMFCameraPosition(
            current.target,
            zoom: current.zoom,
            tilt: targetTilt,
            heading: current.heading
        )

        let update = NMFCameraUpdate(position: newPosition)
        update.animation = animated ? .easeIn : .none
        update.animationDuration = animated ? 0.25 : 0

        mapView.moveCamera(update)
    }
}

// MARK: - Messages

extension MapViewController {
    /// 메시지 배열로 마커를 로딩합니다.
    func loadMessages(_ messages: [Message]) {
        messageMarkerManager.loadMessages(
            messages,
            mapView: mapViewAdapter,
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
        if !didNotifyFirstMapIdle {
            didNotifyFirstMapIdle = true
            onFirstMapIdle?()
        }

        messageMarkerManager.updateClusterModeIfNeeded(
            zoomLevel: mapView.zoomLevel,
            mapView: mapViewAdapter
        )
    }

    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        // 유저가 직접 지도 건드릴 시 추적 해제 (파란 점은 보이도록)
        if reason == NMFMapChangedByGesture {
            naverMapView.mapView.positionMode = .normal
            onUserGesture?()
            return
        }

        // 위치 추적으로 인한 카메라 변경인지 확인
        guard reason == NMFMapChangedByLocation else { return }

        // 위치 모드가 direction 또는 compass인지 확인
        let positionMode = naverMapView.mapView.positionMode
        let isLocationModeOn = positionMode == .direction || positionMode == .compass
        guard isLocationModeOn else { return }

        if !isFollowingUser && isLocationModeOn {
            onFollowRequested?()
            return
        }
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

// MARK: - NMFTileCoverHelperDelegate

extension MapViewController: NMFTileCoverHelperDelegate {
    func onTileChanged(_ addedTileIds: [NSNumber]?, removedTileIds: [NSNumber]?) {
        let addedEmpty = addedTileIds?.isEmpty ?? true
        let removedEmpty = removedTileIds?.isEmpty ?? true
        guard !(addedEmpty && removedEmpty) else { return }

        let center = naverMapView.mapView.cameraPosition.target
        let coordinate = Coordinate(latitude: center.lat, longitude: center.lng)
        let domainBounds = makeBoundingBox(from: naverMapView.mapView)
        let snapshot = currentSnapshot(from: naverMapView.mapView)

        onCameraIdle?(coordinate, domainBounds, snapshot)
    }
}
