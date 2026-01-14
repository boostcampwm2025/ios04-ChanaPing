//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import SwiftUI
import UIKit

import NMapsMap

/// 메시지 마커의 생성 및 관리를 담당하는 클래스
@MainActor
final class MessageMarkerManager {
    /// 단일 버블용 마커 (Place/NoPlace 각각 저장)
    private(set) var singleMarkers: [MarkerGroupKey: NMFMarker] = [:]

    /// 회전/스택 버블용 설정 (2개 이상 메시지)
    private(set) var bubbleConfigs: [MarkerGroupKey: BubbleConfiguration] = [:]

    /// 회전 버블 고정 너비
    private let rotatingBubbleWidth: CGFloat

    init(rotatingBubbleWidth: CGFloat = 170) {
        self.rotatingBubbleWidth = rotatingBubbleWidth
    }

    /// 모든 마커를 지도에서 제거합니다.
    func clearAllMarkers() {
        for (_, marker) in singleMarkers {
            marker.mapView = nil
        }
        singleMarkers.removeAll()

        for (_, config) in bubbleConfigs {
            config.marker.mapView = nil
        }
        bubbleConfigs.removeAll()
    }
    /// GroupedMessage를 기반으로 마커를 생성/업데이트합니다.
    func updateMarkers(
        messageGroupContainer: MessageGroupContainer,
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        clearAllMarkers()

        for (_, messagesInCoordinate) in messageGroupContainer.groups {
            // Place 마커 생성
            let placeMessages = messagesInCoordinate.placeMessages
            let countByPlace = messagesInCoordinate.messageCountByPlace

            createMarker(
                messages: placeMessages,
                coordinate: messagesInCoordinate.getPlaceCoordinate(),
                isPlace: true,
                mapView: mapView,
                onTap: {
                    // 장소 태그 한 개 -> 공간 화면 전환
                    if countByPlace.count == 1,
                       let place = placeMessages.first?.placeTag {
                            onTapPlace?(place)
                    }
                    // 장소 태그 두 개 이상 -> 카드 모달 띄우기
                    else {
                        // TODO: 장소가 두 개 이상 -> 카드 모달 띄우기
                        print("장소 별 메시지 개수: \(countByPlace)")
                    }
                }
            )

            // NoPlace 마커 생성
            let noPlaceMessages = messagesInCoordinate.noPlaceMessages

            createMarker(
                messages: noPlaceMessages,
                coordinate: messagesInCoordinate.getNoPlaceCoordinate(),
                isPlace: false,
                mapView: mapView,
                onTap: {
                    if noPlaceMessages.count >= 2 {
                        // TODO: 스택 펼치기
                        onTapNoPlace?(noPlaceMessages)
                    }
                }
            )
        }
    }
}

// MARK: - Marker 생성

extension MessageMarkerManager {
    private func createMarker(
        messages: [Message],
        coordinate: Coordinate,
        isPlace: Bool,
        mapView: NMFMapView,
        onTap: @escaping () -> Void
    ) {
        guard !messages.isEmpty else { return }

        let position = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let marker = makeMarker(at: position, mapView: mapView)
        let groupKey = MarkerGroupKey(coordinate: coordinate, isPlace: isPlace)

        marker.touchHandler = { _ in
            onTap()
            return true
        }

        if messages.count == 1 {
            let image = renderStaticBubbleImage(for: messages[0], showsAccentLine: true)
            marker.iconImage = NMFOverlayImage(image: image)
            singleMarkers[groupKey] = marker
        } else {
            // TODO: NoPlace의 경우 스택 마커로 변경 필요
            configureBubbleRotation(marker: marker, messages: messages, groupKey: groupKey)
        }
    }

    private func makeMarker(at position: NMGLatLng, mapView: NMFMapView) -> NMFMarker {
        let marker = NMFMarker(position: position)
        marker.anchor = CGPoint(x: 0.5, y: 1.0)
        marker.zIndex = 1000
        marker.isFlat = false
        marker.mapView = mapView
        return marker
    }

    private func configureBubbleRotation(
        marker: NMFMarker,
        messages: [Message],
        groupKey: MarkerGroupKey
    ) {
        guard let current = messages.first else { return }
        let next = messages.count > 1 ? messages[1] : current

        let currentTime = Date().timeIntervalSince1970
        let image = renderStaticRotatingBubbleImage(message: current)
        marker.iconImage = NMFOverlayImage(image: image)

        let config = BubbleConfiguration(
            marker: marker,
            messages: messages,
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
