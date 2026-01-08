//
//  MapViewController.swift
//  Meomun
//
//  Created by hoon on 1/6/26.
//

import NMapsMap
import SwiftUI
import UIKit

final class BubbleConfiguration {
    let marker: NMFMarker
    let messages: [Message] // 같은 장소 태그로 묶인 메시지들
    var currentIndex: Int
    var lastRotationTime: TimeInterval
    var animationStartTime: TimeInterval?
    var animationProgress: Double
    var isAnimating: Bool
    var currentMessage: Message
    var nextMessage: Message

    init(
        marker: NMFMarker,
        messages: [Message],
        currentIndex: Int,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double,
        isAnimating: Bool,
        currentMessage: Message,
        nextMessage: Message
    ) {
        self.marker = marker
        self.messages = messages
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
        self.currentMessage = currentMessage
        self.nextMessage = nextMessage
    }
}

final class MapViewController: UIViewController {

    private var appLifecycleObservers: [NSObjectProtocol] = []

    private var locationManager = CLLocationManager()
    private var didMoveToCurrentLocation = false

    // 일반 버블용 마커
    private var messageMarkers: [UUID: NMFMarker] = [:]

    // 회전 버블용 설정들
    private var bubbleConfigs: [BubbleConfiguration] = []
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

// MARK: - messages

extension MapViewController {
    func updateMessages(_ messages: [Message]) {
        // 1) 기존 마커 전부 제거
        for (_, marker) in messageMarkers {
            marker.mapView = nil
        }
        messageMarkers.removeAll()

        for config in bubbleConfigs {
            config.marker.mapView = nil
        }
        bubbleConfigs.removeAll()

        // 2) placeTag.id 기준으로 그룹핑
        let grouped = Dictionary(grouping: messages) { message in
            message.placeTag?.id ?? message.id
        }

        // 3) 그룹별로 마커 생성
        for (_, groupMessages) in grouped {
            guard let firstMessage = groupMessages.first else { continue }

            let coordinate = NMGLatLng(
                lat: firstMessage.coordinate.latitude,
                lng: firstMessage.coordinate.longitude
            )

            let marker = NMFMarker(position: coordinate)
            marker.anchor = CGPoint(x: 0.5, y: 1.0)
            marker.zIndex = 1000
            marker.isFlat = false
            marker.mapView = naverMapView.mapView

            if groupMessages.count == 1 {
                // 단일 메세지: 일반 버블
                let image = renderStaticBubbleImage(for: firstMessage)
                marker.iconImage = NMFOverlayImage(image: image)

                messageMarkers[firstMessage.id] = marker
            } else {
                // 여러 개: 회전 버블
                let currentTime = Date().timeIntervalSince1970
                let current = groupMessages[0]
                let next = groupMessages[1 % groupMessages.count]

                let image = renderStaticBubbleImage(
                    for: current,
                    showsAccentLine: false
                )
                marker.iconImage = NMFOverlayImage(image: image)

                let config = BubbleConfiguration(
                    marker: marker,
                    messages: groupMessages,
                    currentIndex: 0,
                    lastRotationTime: currentTime,
                    animationStartTime: nil,
                    animationProgress: 0,
                    isAnimating: false,
                    currentMessage: current,
                    nextMessage: next
                )

                bubbleConfigs.append(config)
            }
        }
    }

    private func renderStaticBubbleImage(
        for message: Message,
        showsAccentLine: Bool = true,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let bubble = MessageBubble(
            text: message.content,
            placeName: message.placeTag?.name,
            statusIndicator: showsAccentLine ? (message.isRecent() ? .recent : .normal) : .none
        )

        let renderer = ImageRenderer(content: bubble.padding(4))
        renderer.scale = scale
        renderer.isOpaque = false

        return renderer.uiImage ?? UIImage()
    }

    private func renderRotatingBubbleImage(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let rotateBubbleStack = RotatingMessageBubbleStack(
            current: current,
            next: next,
            progress: progress
        )

        let renderer = ImageRenderer(content: rotateBubbleStack.padding(4))
        renderer.scale = scale
        renderer.isOpaque = false

        return renderer.uiImage ?? UIImage()
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

        for config in bubbleConfigs {
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

        let image = renderRotatingBubbleImage(
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

            let finalImage = renderStaticBubbleImage(
                for: config.nextMessage,
                showsAccentLine: false
            )
            config.marker.iconImage = NMFOverlayImage(image: finalImage)

            let nextNextIndex = (nextIndex + 1) % config.messages.count
            config.currentMessage = config.messages[nextIndex]
            config.nextMessage = config.messages[nextNextIndex]
        }
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
