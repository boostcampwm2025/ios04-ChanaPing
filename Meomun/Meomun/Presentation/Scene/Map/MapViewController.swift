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

    // MARK: - Properties

    private var appLifecycleObservers: [NSObjectProtocol] = []
    private var didMoveToCurrentLocation = false

    // MARK: - Animation Properties

    private var bubbleRotationTimer: Timer?
    private let frameInterval: TimeInterval = 1.0 / 60.0
    private let rotationInterval: TimeInterval = 3.0
    private let animationDuration: TimeInterval = 1.0

    // MARK: - Callback

    private let onTapPlace: ((Place) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?

    // MARK: - Dependencies

    private var locationManager = CLLocationManager()
    private let messageMarkerManager: MessageMarkerManager
    private let rotationAnimator: MessageRotationAnimator

    // MARK: - Init

    init(
        messageMarkerManager: MessageMarkerManager,
        rotationAnimator: MessageRotationAnimator,
        onTapPlace: ((Place) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil
    ) {
        self.messageMarkerManager = messageMarkerManager
        self.rotationAnimator = rotationAnimator
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.messageMarkerManager = MessageMarkerManager()
        self.rotationAnimator = MessageRotationAnimator()
        self.onTapPlace = nil
        self.onTapNoPlace = nil
        super.init(coder: coder)
    }

    private let naverMapView: NMFNaverMapView = {
        let naverMapView = NMFNaverMapView()

        // 지도 UI 설정
        naverMapView.showCompass = false
        naverMapView.showScaleBar = true
        naverMapView.showZoomControls = false
        naverMapView.showLocationButton = true

        // 최소 및 최대 줌 레벨 설정
        naverMapView.mapView.minZoomLevel = 15
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
            AppLog.error("위치 권한이 거부/제한되어 있어 현재 위치로 이동할 수 없습니다.", category: .permission)
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
        AppLog.error(
            "위치 업데이트 실패",
            category: .location,
            error: error
        )
    }
}

// MARK: - Messages

extension MapViewController {
    /// 그룹화된 메시지로 마커를 업데이트합니다.
    func updateGroups(_ groups: MessageGroupContainer) {
        messageMarkerManager.updateMarkers(
            messageGroupContainer: groups,
            mapView: naverMapView.mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
    }
}

// MARK: - Animation

extension MapViewController {
    private func startBubbleRotationTimer() {
        bubbleRotationTimer?.invalidate()

        bubbleRotationTimer = Timer.scheduledTimer(
            withTimeInterval: frameInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateMarkers()
        }

        if let timer = bubbleRotationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopBubbleRotationTimer() {
        bubbleRotationTimer?.invalidate()
        bubbleRotationTimer = nil
    }

    private func updateMarkers() {
        let currentTime = Date().timeIntervalSince1970

        for (_, config) in messageMarkerManager.bubbleConfigs {
            guard config.messages.count > 1 else { continue }

            if config.isAnimating {
                rotationAnimator.updateAnimation(for: config, currentTime: currentTime)

                let image = messageMarkerManager.renderRotatingBubbleImage(
                    current: config.currentMessage,
                    next: config.nextMessage,
                    progress: config.animationProgress
                )
                config.marker.iconImage = NMFOverlayImage(image: image)
            } else {
                if rotationAnimator.shouldStartAnimation(for: config, currentTime: currentTime) {
                    config.startAnimation(at: currentTime)
                }
            }
        }
    }
}

// MARK: - MapViewWrapper

struct MapViewWrapper: UIViewControllerRepresentable {
    private let messageGroupContainer: MessageGroupContainer
    private let onTapPlace: ((Place) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?

    private let messageMarkerManager: MessageMarkerManager
    private let rotationAnimator: MessageRotationAnimator

    init(
        markerManager: MessageMarkerManager,
        rotationAnimator: MessageRotationAnimator,
        messageContainer: MessageGroupContainer,
        onTapPlace: ((Place) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil
    ) {
        self.messageMarkerManager = markerManager
        self.rotationAnimator = rotationAnimator
        self.messageGroupContainer = messageContainer
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
    }

    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController(
            messageMarkerManager: messageMarkerManager,
            rotationAnimator: rotationAnimator,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
        viewController.updateGroups(messageGroupContainer)
        return viewController
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        uiViewController.updateGroups(messageGroupContainer)
    }
}
