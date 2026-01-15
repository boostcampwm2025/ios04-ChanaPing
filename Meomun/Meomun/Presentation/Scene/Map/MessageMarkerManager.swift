//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import UIKit

import NMapsMap

/// 메시지 마커의 생성 및 관리를 담당하는 클래스
@MainActor
final class MessageMarkerManager {
    /// 단일 버블용 마커 (Place/NoPlace 각각 저장)
    private(set) var singleMarkers: [MarkerGroupKey: NMFMarker] = [:]

    /// 회전/스택 버블용 설정 (2개 이상 메시지)
    private(set) var bubbleAnimationState: [MarkerGroupKey: AnimationState] = [:]

    /// 회전 버블용 마커 (AnimationState와 별도로 관리)
    private(set) var bubbleMarkers: [MarkerGroupKey: NMFMarker] = [:]

    private let rotationAnimator: MessageRotationAnimator
    private let bubbleImageRenderer: BubbleImageRenderer

    init(
        rotationAnimator: MessageRotationAnimator,
        bubbleImageRenderer: BubbleImageRenderer
    ) {
        self.rotationAnimator = rotationAnimator
        self.bubbleImageRenderer = bubbleImageRenderer
    }

    /// 모든 마커를 지도에서 제거합니다.
    func clearAllMarkers() {
        for (_, marker) in singleMarkers {
            marker.mapView = nil
        }
        singleMarkers.removeAll()

        for (_, marker) in bubbleMarkers {
            marker.mapView = nil
        }
        bubbleMarkers.removeAll()
        bubbleAnimationState.removeAll()
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
            let image = bubbleImageRenderer.renderSingleBubble(message: messages[0], showsAccentLine: true)
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

        let currentTime = Date().timeIntervalSince1970
        let image = bubbleImageRenderer.renderSingleBubble(message: current, showsAccentLine: false)
        marker.iconImage = NMFOverlayImage(image: image)

        let state = AnimationState(
            messages: messages,
            currentIndex: 0,
            lastRotationTime: currentTime
        )

        bubbleAnimationState[groupKey] = state
        bubbleMarkers[groupKey] = marker
    }

    /// 그룹 키로 마커를 가져옵니다.
    func getMarker(for groupKey: MarkerGroupKey) -> NMFMarker? {
        return bubbleMarkers[groupKey]
    }
}

// MARK: - Update Marker for Animation

extension MessageMarkerManager {
    /// 애니메이션 상태를 업데이트합니다. (매 프레임 호출)
    func updateAnimations() {
        let currentTime = Date().timeIntervalSince1970

        for (groupKey, state) in bubbleAnimationState {
            guard state.messages.count > 1 else { continue }
            guard let marker = getMarker(for: groupKey) else { continue }

            if state.isAnimating {
                rotationAnimator.updateAnimation(for: state, currentTime: currentTime)

                let image = bubbleImageRenderer.renderRotatingBubble(
                    current: state.currentMessage,
                    next: state.nextMessage,
                    progress: state.animationProgress
                )
                marker.iconImage = NMFOverlayImage(image: image)
            } else {
                if rotationAnimator.shouldStartAnimation(for: state, currentTime: currentTime) {
                    state.startAnimation(at: currentTime)
                }
            }
        }
    }
}
