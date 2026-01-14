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

    // 마커 탭 콜백 (장소 태그가 있는 회전 버블 탭 시)
    private let onTapPlace: ((Place) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?

    private var appLifecycleObservers: [NSObjectProtocol] = []

    private var locationManager = CLLocationManager()
    private var didMoveToCurrentLocation = false

    private let messageMarkerManager: MessageMarkerManager

    // MARK: - Init

    init(
        messageMarkerManager: MessageMarkerManager,
        onTapPlace: ((Place) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil
    ) {
        self.messageMarkerManager = messageMarkerManager
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.messageMarkerManager = MessageMarkerManager()
        self.onTapPlace = nil
        self.onTapNoPlace = nil
        super.init(coder: coder)
    }

    // 회전 버블용 설정들
    private var bubbleRotationTimer: Timer?
    private let frameInterval: TimeInterval = 1.0 / 60.0
    private let rotationInterval: TimeInterval = 3.0
    private let animationDuration: TimeInterval = 1.0

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

// MARK: - Messages

extension MapViewController {
    /// 그룹화된 메시지로 마커를 업데이트합니다.
    func updateGroups(_ groups: MessagesByCoordinate) {
        messageMarkerManager.updateMarkers(
            groups: groups,
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
                updateAnimation(for: config, currentTime: currentTime)
            } else {
                if currentTime - config.lastRotationTime >= rotationInterval {
                    startAnimation(for: config, currentTime: currentTime)
                }
            }
        }
    }

    private func startAnimation(for config: BubbleConfiguration, currentTime: TimeInterval) {
        guard !config.isAnimating else { return }

        config.isAnimating = true
        config.animationStartTime = currentTime
        config.animationProgress = 0.0

        let nextIndex = (config.currentIndex + 1) % config.messages.count
        config.nextMessage = config.messages[nextIndex]
        config.currentMessage = config.messages[config.currentIndex]
    }

    private func updateAnimation(for config: BubbleConfiguration, currentTime: TimeInterval) {
        guard let startTime = config.animationStartTime else {
            config.isAnimating = false
            return
        }

        let elapsed = currentTime - startTime
        let progress = min(elapsed / animationDuration, 1.0)
        config.animationProgress = progress

        let image = messageMarkerManager.renderRotatingBubbleImage(
            current: config.currentMessage,
            next: config.nextMessage,
            progress: progress
        )
        config.marker.iconImage = NMFOverlayImage(image: image)

        if progress >= 1.0 {
            let nextIndex = (config.currentIndex + 1) % config.messages.count
            config.currentIndex = nextIndex
            config.isAnimating = false
            config.animationProgress = 0
            config.animationStartTime = nil
            config.lastRotationTime = currentTime

            let finalImage = messageMarkerManager.renderStaticRotatingBubbleImage(message: config.nextMessage)
            config.marker.iconImage = NMFOverlayImage(image: finalImage)

            let nextNextIndex = (nextIndex + 1) % config.messages.count
            config.currentMessage = config.messages[nextIndex]
            config.nextMessage = config.messages[nextNextIndex]
        }
    }
}

// MARK: - MapViewWrapper

struct MapViewWrapper: UIViewControllerRepresentable {
    private let messagesByCoordinate: MessagesByCoordinate
    private let onTapPlace: ((Place) -> Void)?

    private let messageMarkerManager: MessageMarkerManager

    init(
        messageMarkerManager: MessageMarkerManager,
        groupedMessages: MessagesByCoordinate,
        onTapPlace: ((Place) -> Void)? = nil
    ) {
        self.messageMarkerManager = messageMarkerManager
        self.messagesByCoordinate = groupedMessages
        self.onTapPlace = onTapPlace
    }

    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController(
            messageMarkerManager: messageMarkerManager,
            onTapPlace: onTapPlace
        )
        viewController.updateGroups(messagesByCoordinate)
        return viewController
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        uiViewController.updateGroups(messagesByCoordinate)
    }
}
