//
//  MainMapViewController.swift
//  Fleeting-Prototype
//
//  Created by MinwooJe on 12/18/25.
//

import SwiftUI
import UIKit

import NMapsMap

final class BubbleConfiguration {
    let marker: NMFMarker
    let messages: [String]
    var currentIndex: Int
    var lastRotationTime: TimeInterval
    var animationStartTime: TimeInterval?
    var animationProgress: Double
    var isAnimating: Bool
    var currentText: String
    var nextText: String

    init(
        marker: NMFMarker,
        messages: [String],
        currentIndex: Int,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double,
        isAnimating: Bool,
        currentText: String,
        nextText: String
    ) {
        self.marker = marker
        self.messages = messages
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
        self.currentText = currentText
        self.nextText = nextText
    }
}

struct AnimatedBubbleStack: View {
    let currentText: String
    let nextText: String
    let animationProgress: Double // 0.0 ~ 1.0

    var body: some View {
        ZStack {
            // 다음 메시지 (아래에서 위로 나타남)
            if animationProgress > 0 {
                Text(nextText)
                    .opacity(animationProgress)
                    .offset(y: (1 - animationProgress) * 30)
            }

            // 현재 메시지 (위로 사라짐)
            Text(currentText)
                .opacity(1 - animationProgress)
                .offset(y: -animationProgress * 30)
        }
        .shadow(radius: 6, y: 2)
        .padding()
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

final class MainMapViewController: UIViewController {

    private var bubbleConfigs: [BubbleConfiguration] = []

    private var bubbleRotationTimer: Timer?
    private let frameInterval: TimeInterval = 1.0 / 60.0 // 60fps
    private let rotationInterval: TimeInterval = 1.0 // 1초마다 로테이션
    private let animationDuration: TimeInterval = 1.2

    private let naverMapView: NMFNaverMapView = {
        let naverMapView = NMFNaverMapView()

        // 지도 UI 설정
        naverMapView.showCompass = false
        naverMapView.showScaleBar = false
        naverMapView.showZoomControls = false
        naverMapView.showLocationButton = true

        // 지도 스타일
        naverMapView.mapView.customStyleId = "9d41e3bf-0e89-45bc-8261-776fcdd1660d"

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

    override func viewDidLoad() {
        super.viewDidLoad()
        addDummyMarkers(count: 100, baseLat: 37.5665, baseLng: 126.9780)
        configureInitialSettings()
        configureSubviews()
        configureLayout()
    }

    deinit {
        stopTimer()
    }
}

// MARK: Configure Initial Settings

extension MainMapViewController {
    private func configureInitialSettings() {
        startTimer()
    }

    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.updateMarkers()
        }
        RunLoop.main.add(timer, forMode: .common)
        bubbleRotationTimer = timer
    }

    private func stopTimer() {
        bubbleRotationTimer?.invalidate()
        bubbleRotationTimer = nil
    }
}

// MARK: - Bubble Animation

extension MainMapViewController {
    private func updateMarkers() {
        let currentTime = Date().timeIntervalSince1970

        for config in bubbleConfigs {
            guard config.messages.count > 1 else { continue }

            if config.isAnimating {
                updateAnimation(for: config, currentTime: currentTime)
            } else {
                // 로테이션 시간 확인
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

        // 다음 메시지 인덱스 계산
        let nextIndex = (config.currentIndex + 1) % config.messages.count
        config.nextText = config.messages[nextIndex]
        config.currentText = config.messages[config.currentIndex]
    }

    private func updateAnimation(for config: BubbleConfiguration, currentTime: TimeInterval) {
        guard let startTime = config.animationStartTime else {
            config.isAnimating = false
            return
        }

        let elapsedTime = currentTime - startTime
        let progress = min(elapsedTime / animationDuration, 1.0)
        config.animationProgress = progress

        let image = renderAnimatedBubbleImage(
            currentText: config.currentText,
            nextText: config.nextText,
            animationProgress: progress
        )
        config.marker.iconImage = NMFOverlayImage(image: image)

        // 로테이션 완료 후 다음 로테이션 준비
        if progress >= 1.0 {
            let nextIndex = (config.currentIndex + 1) % config.messages.count
            config.currentIndex = nextIndex
            config.isAnimating = false
            config.animationProgress = 0.0
            config.animationStartTime = nil
            config.lastRotationTime = currentTime

            // 최종 상태로 업데이트 (다음 메시지만 표시)
            let finalImage = renderBubbleImage(text: config.nextText)
            config.marker.iconImage = NMFOverlayImage(image: finalImage)

            // 다음 메시지 준비
            let nextNextIndex = (nextIndex + 1) % config.messages.count
            config.currentText = config.messages[nextIndex]
            config.nextText = config.messages[nextNextIndex]
        }
    }

    // TODO: UIScreen.main 대체 필요 (deprecated)
    private func renderBubbleImage(text: String, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let renderer = ImageRenderer(
            content: Text(text)
                .shadow(radius: 6, y: 2)
                .padding()
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        renderer.scale = scale
        renderer.isOpaque = false

        guard let image = renderer.uiImage else {
            return UIImage()
        }

        return image
    }

    // TODO: UIScreen.main 대체 필요 (deprecated)
    func renderAnimatedBubbleImage(
        currentText: String,
        nextText: String,
        animationProgress: Double,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let renderer = ImageRenderer(
            content: AnimatedBubbleStack(
                currentText: currentText,
                nextText: nextText,
                animationProgress: animationProgress
            )
        )
        renderer.scale = scale
        renderer.isOpaque = false

        guard let image = renderer.uiImage else {
            return UIImage()
        }
        return image
    }
}

// MARK: - Configure UI

extension MainMapViewController {
    private func configureSubviews() {
        [naverMapView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func configureLayout() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            naverMapView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            naverMapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            naverMapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            naverMapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
}

extension MainMapViewController {
    func addDummyMarkers(count: Int, baseLat: Double, baseLng: Double) {
        let dummyMessages = [
            ["좋은 곳이에요", "추천합니다"], ["분위기 좋아요", "조용해요"], ["커피 맛있어요", "다시 올게요"],
            ["편안한 공간", "좋아요"], ["친절해요", "만족합니다"], ["깔끔해요", "좋아요"],
            ["조용해요", "집중하기 좋아요"], ["분위기 최고", "추천합니다"], ["편리해요", "좋은 곳이에요"],
            ["만족스러워요", "다시 올게요"], ["좋아요", "추천합니다"], ["편안해요", "조용해요"],
            ["커피 좋아요", "맛있어요"], ["분위기 좋아요", "좋은 곳이에요"], ["깔끔하고 좋아요", "만족합니다"],
            ["조용하고 좋아요", "집중하기 좋아요"], ["편리하고 좋아요", "추천합니다"], ["친절하고 좋아요", "만족스러워요"],
            ["좋은 공간이에요", "다시 올게요"], ["편안한 곳이에요", "좋아요"], ["커피 맛있고 좋아요", "추천합니다"],
            ["분위기 최고예요", "좋은 곳이에요"], ["조용하고 편안해요", "만족합니다"], ["깔끔하고 좋아요", "다시 올게요"],
            ["편리하고 좋아요", "좋아요"], ["친절하고 좋아요", "추천합니다"], ["좋은 공간이에요", "만족스러워요"],
            ["편안한 곳이에요", "좋아요"], ["커피 좋아요", "맛있어요"], ["분위기 좋아요", "조용해요"],
            ["깔끔해요", "좋아요"], ["편리해요", "추천합니다"], ["친절해요", "만족합니다"],
            ["좋은 곳이에요", "다시 올게요"], ["편안해요", "좋아요"], ["커피 맛있어요", "추천합니다"],
            ["분위기 좋아요", "좋은 곳이에요"], ["조용해요", "집중하기 좋아요"], ["깔끔하고 좋아요", "만족스러워요"],
            ["편리하고 좋아요", "좋아요"], ["친절하고 좋아요", "추천합니다"], ["좋은 공간이에요", "다시 올게요"],
            ["편안한 곳이에요", "만족합니다"], ["커피 좋아요", "맛있어요"], ["분위기 최고예요", "좋아요"],
            ["조용하고 편안해요", "추천합니다"], ["깔끔하고 좋아요", "좋은 곳이에요"], ["편리하고 좋아요", "만족스러워요"],
            ["친절하고 좋아요", "다시 올게요"], ["좋은 공간이에요", "좋아요"], ["편안한 곳이에요", "추천합니다"],
            ["커피 맛있고 좋아요", "만족합니다"], ["분위기 좋아요", "조용해요"], ["조용하고 좋아요", "집중하기 좋아요"],
            ["깔끔해요", "좋아요"], ["편리해요", "추천합니다"], ["친절해요", "만족스러워요"],
            ["좋은 곳이에요", "다시 올게요"], ["편안해요", "좋아요"], ["커피 좋아요", "맛있어요"],
            ["분위기 좋아요", "추천합니다"], ["조용해요", "좋은 곳이에요"], ["깔끔하고 좋아요", "만족합니다"],
            ["편리하고 좋아요", "다시 올게요"], ["친절하고 좋아요", "좋아요"], ["좋은 공간이에요", "추천합니다"],
            ["편안한 곳이에요", "만족스러워요"], ["커피 맛있어요", "좋아요"], ["분위기 최고예요", "조용해요"],
            ["조용하고 편안해요", "집중하기 좋아요"], ["깔끔하고 좋아요", "좋아요"], ["편리하고 좋아요", "추천합니다"],
            ["친절하고 좋아요", "만족합니다"], ["좋은 공간이에요", "다시 올게요"], ["편안한 곳이에요", "좋아요"],
            ["커피 좋아요", "맛있어요"], ["분위기 좋아요", "추천합니다"], ["조용하고 좋아요", "좋은 곳이에요"],
            ["깔끔해요", "만족스러워요"], ["편리해요", "다시 올게요"], ["친절해요", "좋아요"],
            ["좋은 곳이에요", "추천합니다"], ["편안해요", "만족합니다"], ["커피 맛있고 좋아요", "조용해요"],
            ["분위기 좋아요", "집중하기 좋아요"], ["조용해요", "좋아요"], ["깔끔하고 좋아요", "추천합니다"],
            ["편리하고 좋아요", "만족스러워요"], ["친절하고 좋아요", "다시 올게요"], ["좋은 공간이에요", "좋아요"],
            ["편안한 곳이에요", "추천합니다"], ["커피 좋아요", "맛있어요"], ["분위기 최고예요", "좋은 곳이에요"],
            ["조용하고 편안해요", "만족합니다"], ["깔끔하고 좋아요", "다시 올게요"], ["편리하고 좋아요", "좋아요"], ["친절하고 좋아요", "추천합니다"],
            ["좋은 공간이에요", "만족스러워요"], ["편안한 곳이에요", "조용해요"], ["커피 맛있어요", "집중하기 좋아요"], ["분위기 좋아요", "좋아요"],
            ["조용하고 좋아요", "추천합니다"], ["깔끔해요", "만족합니다"], ["편리해요", "다시 올게요"], ["친절해요", "좋아요"]
        ]

        // 기존 마커 위치 주변에 더미 마커 생성
        let latOffset = 0.01  // 약 1km 범위
        let lngOffset = 0.01  // 약 1km 범위

        for idx in 0..<count {
            // 격자 패턴으로 배치 (10x10)
            let row = idx / 10
            let col = idx % 10

            // 작은 랜덤 오프셋 추가하여 자연스럽게 배치
            let lat = baseLat + (Double(row) / 10.0 - 0.5) * latOffset + Double.random(in: -0.001...0.001)
            let lng = baseLng + (Double(col) / 10.0 - 0.5) * lngOffset + Double.random(in: -0.001...0.001)

            let messages = dummyMessages[idx % dummyMessages.count]
            addBubble(lat: lat, lng: lng, messages: messages)
        }
    }

    private func addBubble(lat: Double, lng: Double, messages: [String]) {
        guard !messages.isEmpty else { return }

        let marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))

        // 초기 메시지 렌더링
        let initialText = messages[0]
        let uiImage = renderBubbleImage(text: initialText)
        marker.iconImage = NMFOverlayImage(image: uiImage)

        marker.anchor = CGPoint(x: 0.5, y: 1.0)
        marker.zIndex = 1000
        marker.isFlat = false
        marker.mapView = naverMapView.mapView

        // BubbleConfiguration 생성
        let currentTime = Date().timeIntervalSince1970
        let currentText = messages[0]
        let nextText = messages.count > 1 ? messages[1] : messages[0]

        let config = BubbleConfiguration(
            marker: marker,
            messages: messages,
            currentIndex: 0,
            lastRotationTime: currentTime,
            animationStartTime: nil,
            animationProgress: 0.0,
            isAnimating: false,
            currentText: currentText,
            nextText: nextText
        )

        bubbleConfigs.append(config)
    }
}
