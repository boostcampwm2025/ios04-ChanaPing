//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import SwiftUI
import UIKit

import NMapsMap

final class MessageMarkerManager {
    /// 단일 버블용 마커 (Place/NoPlace 각각 저장)
    private(set) var singleMarkers: [BubbleGroupKey: NMFMarker] = [:]

    /// 회전/스택 버블용 설정 (2개 이상 메시지)
    private(set) var bubbleConfigs: [BubbleGroupKey: BubbleConfiguration] = [:]

    /// 회전 버블 고정 너비
    private let rotatingBubbleWidth: CGFloat

    init(rotatingBubbleWidth: CGFloat = 170) {
        self.rotatingBubbleWidth = rotatingBubbleWidth
    }

    /// 그룹화된 메시지로 마커를 업데이트합니다.
    func updateGroups(
        _ groups: GroupedMessage,
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?
    ) {
        // 1) 기존 마커 전부 제거
        for (_, marker) in singleMarkers {
            marker.mapView = nil
        }
        singleMarkers.removeAll()

        for (_, config) in bubbleConfigs {
            config.marker.mapView = nil
        }
        bubbleConfigs.removeAll()

        // 2) 그룹별로 마커 생성
        for (groupKey, groupMessages) in groups.messages {
            guard let firstMessage = groupMessages.first else { continue }

            let coordinate = NMGLatLng(
                lat: firstMessage.location.latitude,
                lng: firstMessage.location.longitude
            )

            let marker = NMFMarker(position: coordinate)
            marker.anchor = CGPoint(x: 0.5, y: 1.0)
            marker.zIndex = 1000
            marker.isFlat = false
            marker.mapView = mapView

            // 마커 탭 핸들러 설정
            marker.touchHandler = { _ in
                // 조건: .places 그룹 + 메시지 2개 이상 (회전 버블)
                if case .places = groupKey,
                   groupMessages.count >= 2,
                   let place = groupMessages.first?.placeTag {
                    onTapPlace?(place)
                }
                return true
            }

            if groupMessages.count == 1 {
                // 단일 메시지: 일반 버블
                let image = renderStaticBubbleImage(for: firstMessage)
                marker.iconImage = NMFOverlayImage(image: image)

                singleMarkers[groupKey] = marker
            } else {
                // 여러 개: 회전 버블
                let currentTime = Date().timeIntervalSince1970
                let current = groupMessages[0]
                let next = groupMessages[1 % groupMessages.count]

                let image = renderStaticRotatingBubbleImage(message: current)
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

                bubbleConfigs[groupKey] = config
            }
        }
    }
}

// MARK: - Rendering

extension MessageMarkerManager {
    func renderStaticBubbleImage(
        for message: Message,
        showsAccentLine: Bool = true,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let bubble = MessageBubble(
            placeName: message.placeTag?.name,
            statusIndicator: showsAccentLine ? (message.isRecent() ? .recent : .normal) : .none,
            layout: showsAccentLine ? .flexible : .fixedWidth(rotatingBubbleWidth)
        ) {
            BubbleText(text: message.content)
        }

        let renderer = ImageRenderer(content: bubble.padding(4))
        renderer.scale = scale
        renderer.isOpaque = false

        return renderer.uiImage ?? UIImage()
    }

    func renderRotatingBubbleImage(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let bubble = MessageBubble(
            placeName: current.placeTag?.name,
            statusIndicator: .none,
            layout: .fixedWidth(rotatingBubbleWidth)
        ) {
            RotatingTextStack(
                currentText: current.content,
                nextText: next.content,
                progress: progress
            )
        }

        let renderer = ImageRenderer(content: bubble.padding(4))
        renderer.scale = scale
        renderer.isOpaque = false

        return renderer.uiImage ?? UIImage()
    }

    func renderStaticRotatingBubbleImage(
        message: Message,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let bubble = MessageBubble(
            placeName: message.placeTag?.name,
            statusIndicator: .none,
            layout: .fixedWidth(rotatingBubbleWidth)
        ) {
            BubbleText(text: message.content)
        }

        let renderer = ImageRenderer(content: bubble.padding(4))
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
}
