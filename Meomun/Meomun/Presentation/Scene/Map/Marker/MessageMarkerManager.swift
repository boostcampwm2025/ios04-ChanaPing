//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import UIKit

import NMapsMap

enum MarkerPlaceholder {
    static let transparent1px: UIImage = {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }()

    static let overlayImage: NMFOverlayImage = {
        NMFOverlayImage(image: transparent1px)
    }()
}

// MARK: - MessageMarkerManager

/// 지도 위 메시지 마커의 생성, 업데이트, 애니메이션을 관리하는 객체입니다.
///
/// ## 데이터 구조
/// ```
/// placeMessagesByCoord: [좌표: [장소 태그가 있는 메시지들]]
/// noPlaceMessagesByCoord: [좌표: [장소 태그가 없는 메시지들]]
/// markers: [마커키: 네이버맵 마커]
/// animationStates: [마커키: 애니메이션 상태]
/// renderTasks: [마커키: 렌더링 Task] (누적 방지, 최신만 반영)
/// fadeTasks:   [마커키: 페이드 Task] (페이드 애니메이션 중복 방지)
/// hasFadedIn:  Set<마커키> (마커별 최초 1회 페이드 적용 여부)
/// ```
///
/// ## 사용 흐름
/// ```
/// 1. loadMessages() -> 초기 메시지 로딩 (전체 마커 생성)
/// 2. handleEvent() -> 실시간 이벤트 처리 (해당 좌표의 마커/상태 갱신 + 필요 시 아이콘 재렌더)
/// 3. updateAnimations() -> 애니메이션 대상 마커는 매 프레임 iconImage 갱신 (60fps)
/// ```
@MainActor
final class MessageMarkerManager {

    /// 장소 태그가 있는 메시지들 (좌표별로 그룹화)
    private var placeMessagesByCoord: [Coordinate: [Message]] = [:]

    /// 장소 태그가 없는 메시지들 (좌표별로 그룹화)
    private var noPlaceMessagesByCoord: [Coordinate: [Message]] = [:]

    /// 지도에 표시된 마커들
    private var markers: [MarkerGroupKey: NMFMarker] = [:]

    /// 마커 별 회전 애니메이션 상태 (2개 이상 메시지가 있는 마커만 해당)
    private var animationStates: [MarkerGroupKey: BubbleAnimationState] = [:]

    /// 한 마커에 표시할 최대 메시지 수 (기본값: 10)
    private let displayLimit: Int

    /// 마커별 렌더링 Task (누적 방지, 최신만 반영)
    private var renderTasks: [MarkerGroupKey: Task<Void, Never>] = [:]

    /// 페이드 관리용 Task
    private var fadeTasks: [MarkerGroupKey: Task<Void, Never>] = [:]

    /// 마커 페이드인 여부 상태 플래그
    private var hasFadedIn: Set<MarkerGroupKey> = []

    // MARK: - Dependencies

    private let rotationAnimator: MessageRotationAnimator
    private let bubbleImageRenderer: BubbleImageRenderer

    init(
        rotationAnimator: MessageRotationAnimator,
        bubbleImageRenderer: BubbleImageRenderer,
        displayLimit: Int = 10
    ) {
        self.rotationAnimator = rotationAnimator
        self.bubbleImageRenderer = bubbleImageRenderer
        self.displayLimit = displayLimit
    }
}

// MARK: - 마커 기본 생성

extension MessageMarkerManager {
    /// 네이버맵 마커 객체를 생성합니다.
    ///  - 기본 핀 깜빡임 방지를 위해 투명 placeholder icon을 먼저 세팅하고,
    ///  - 최초 1회는 렌더링 완료 후 페이드 인, 이후 갱신은 alpha = 1 유지한 채 iconImage만 교체
    private func makeMarker(at position: NMGLatLng, mapView: NMFMapView) -> NMFMarker {
        let marker = NMFMarker(position: position)
        marker.anchor = CGPoint(x: 0.5, y: 1.0)   // 마커 하단 중앙이 좌표 위치
        marker.zIndex = 1000                      // 다른 오버레이보다 위에 표시
        marker.isFlat = false                     // 3D 틸트 시에도 수직 유지

        marker.iconImage = MarkerPlaceholder.overlayImage
        marker.alpha = 0.0

        marker.mapView = mapView                  // 지도에 마커 표시
        return marker
    }
}

extension MessageMarkerManager {

    /// 초기 메시지 로딩 (앱 시작 또는 화면 진입 시 호출)
    ///
    /// 기존 데이터를 모두 초기화하고 전달받은 메시지들로 마커를 새로 생성합니다.
    /// Place 메시지를 먼저 저장한 후 NoPlace 메시지를 저장하여 좌표 겹침 시 오프셋을 적용합니다.
    ///
    /// - Parameters:
    ///   - onTapPlace: Place 마커 탭 시 콜백 (장소 정보 전달)
    ///   - onTapNoPlace: NoPlace 마커 탭 시 콜백 (메시지 배열 전달)
    func loadMessages(
        _ messages: [Message],
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // 1. 기존 데이터 모두 제거
        clearAll()

        // 2. 메시지를 오래된 순으로 정렬 (suffix로 최신 N개를 가져오기 위함)
        let sortedMessages = messages.sorted { $0.createdAt < $1.createdAt }

        // 3. Place 메시지 먼저 저장 (좌표 확정)
        for message in sortedMessages where message.placeTag != nil {
            insertMessage(message)
        }

        // 4. NoPlace 메시지 저장 (Place 좌표와 겹치면 오프셋 적용)
        for message in sortedMessages where message.placeTag == nil {
            insertMessage(message)
        }

        // 5. 저장된 메시지 기반으로 모든 마커 생성
        rebuildAllMarkers(mapView: mapView, onTapPlace: onTapPlace, onTapNoPlace: onTapNoPlace)
    }

    // TODO: - handleEvent 정리 (실시간 이벤트 없으므로)

    /// 실시간 이벤트 처리 (메시지 추가/삭제 시 호출)
    /// - Parameters:
    ///   - event: 메시지 이벤트 (insert 또는 delete)
    ///   - onTapPlace: Place 마커 탭 시 콜백
    ///   - onTapNoPlace: NoPlace 마커 탭 시 콜백
    func handleEvent(
        _ event: MessageEvent,
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        let coord = event.message.coordinate

        // 1. 이벤트 타입에 따라 메시지 저장소 업데이트
        switch event.type {
        case .insert:
            insertMessage(event.message)

        case .delete:
            removeMessage(event.message)
        }

        // 2. 해당 좌표의 마커 업데이트
        updateMarkersForCoordinate(coord, mapView: mapView, onTapPlace: onTapPlace, onTapNoPlace: onTapNoPlace)
    }
}

// MARK: - 메시지 관리

extension MessageMarkerManager {

    /// 새로운 메시지를 그룹화하여 저장합니다.
    ///
    /// placeTag 유무에 따라 placeMessagesByCoord 또는 noPlaceMessagesByCoord에 저장합니다.
    /// NoPlace 메시지가 Place 메시지 좌표와 겹치면 오프셋을 적용합니다.
    /// 메시지는 오래된 순(createdAt 오름차순)으로 저장되며, 새 메시지는 항상 뒤에 추가됩니다.
    /// 표시할 때는 suffix(displayLimit)로 최신 메시지들을 가져옵니다.
    private func insertMessage(_ message: Message) {
        if message.placeTag != nil {
            // 장소 태그가 있는 메시지 -> 원본 좌표로 저장
            let coord = message.coordinate
            placeMessagesByCoord[coord, default: []].append(message)
        } else {
            // 장소 태그가 없는 메시지 -> Place 좌표와 겹치면 오프셋 적용
            let coord = displayCoordinate(for: message)
            noPlaceMessagesByCoord[coord, default: []].append(message)
        }
    }

    /// NoPlace 메시지의 표시용 좌표 계산
    /// Place 좌표와 겹치면 오프셋 적용, 아니면 원본 좌표 반환
    private func displayCoordinate(for message: Message) -> Coordinate {
        let originalCoord = message.coordinate

        // Place 메시지가 해당 좌표에 있으면 오프셋 적용
        if placeMessagesByCoord[originalCoord] != nil {
            return originalCoord.offset(for: message.id)
        }

        return originalCoord
    }

    /// 메시지를 제거합니다.
    /// NoPlace 메시지의 경우 원본 좌표와 오프셋 좌표 모두에서 검색합니다.
    private func removeMessage(_ message: Message) {
        if message.placeTag != nil {
            // Place 메시지 제거
            let coord = message.coordinate
            placeMessagesByCoord[coord]?.removeAll { $0.id == message.id }

            // 빈 배열이면 키 삭제
            if placeMessagesByCoord[coord]?.isEmpty == true {
                placeMessagesByCoord.removeValue(forKey: coord)
            }
        } else {
            // NoPlace 메시지 제거 - 원본 좌표와 오프셋 좌표 모두 확인
            let originalCoord = message.coordinate
            let offsetCoord = originalCoord.offset(for: message.id)

            // 원본 좌표에서 찾기
            if noPlaceMessagesByCoord[originalCoord]?.contains(where: { $0.id == message.id }) == true {
                noPlaceMessagesByCoord[originalCoord]?.removeAll { $0.id == message.id }
                if noPlaceMessagesByCoord[originalCoord]?.isEmpty == true {
                    noPlaceMessagesByCoord.removeValue(forKey: originalCoord)
                }
            }
            // 오프셋 좌표에서 찾기
            else if noPlaceMessagesByCoord[offsetCoord]?.contains(where: { $0.id == message.id }) == true {
                noPlaceMessagesByCoord[offsetCoord]?.removeAll { $0.id == message.id }
                if noPlaceMessagesByCoord[offsetCoord]?.isEmpty == true {
                    noPlaceMessagesByCoord.removeValue(forKey: offsetCoord)
                }
            }
        }
    }

    /// 모든 데이터를 초기화합니다.
    ///
    /// - 지도에서 모든 마커 제거
    /// - 마커 딕셔너리 초기화
    /// - 애니메이션 상태 초기화
    /// - 메시지 저장소 초기화
    /// - 진행 중인 렌더링 Task 취소 (누적 방지)
    /// - fadeTasks 취소
    /// - hasFadedIn 초기화
    private func clearAll() {
        // 지도에서 마커 제거
        for (_, marker) in markers {
            marker.mapView = nil
        }
        markers.removeAll()
        animationStates.removeAll()
        placeMessagesByCoord.removeAll()
        noPlaceMessagesByCoord.removeAll()

        for (_, task) in renderTasks { task.cancel() }
        renderTasks.removeAll()

        for (_, task) in fadeTasks { task.cancel() }
        fadeTasks.removeAll()
        hasFadedIn.removeAll()
    }
}

// MARK: - 마커 생성 및 업데이트

extension MessageMarkerManager {

    /// 저장된 모든 좌표에 대해 마커를 생성합니다.
    ///
    /// Place와 NoPlace 메시지가 있는 모든 좌표를 순회하며
    /// 각 좌표에 대해 마커를 생성합니다.
    private func rebuildAllMarkers(
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // Place와 NoPlace 좌표를 합집합으로 구함
        let totalCoordinates = Set(placeMessagesByCoord.keys).union(Set(noPlaceMessagesByCoord.keys))

        for coord in totalCoordinates {
            updateMarkersForCoordinate(coord, mapView: mapView, onTapPlace: onTapPlace, onTapNoPlace: onTapNoPlace)
        }
    }

    /// 특정 좌표의 마커들을 업데이트합니다.
    ///
    /// 하나의 좌표에는 최대 2개의 마커가 있을 수 있습니다:
    /// 1. Place 마커: 장소 태그가 있는 메시지들
    /// 2. NoPlace 마커: 장소 태그가 없는 메시지들
    private func updateMarkersForCoordinate(
        _ coord: Coordinate,
        mapView: NMFMapView,
        onTapPlace: ((Place) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // Place 마커 생성/업데이트
        updateMarker(
            coord: coord,
            isPlace: true,
            mapView: mapView,
            onTap: { messages in
                // 탭 시 실행될 로직
                guard let place = messages.first?.placeTag else { return }
                let uniquePlaces = Set(messages.compactMap { $0.placeTag })

                if uniquePlaces.count == 1 {
                    // 장소가 1개 -> Space 화면으로 이동
                    onTapPlace?(place)
                } else {
                    // TODO: 장소가 여러 개 -> 선택 모달 표시
                    print("장소 여러 개: \(uniquePlaces.count)")
                }
            }
        )

        // NoPlace 마커 생성/업데이트
        updateMarker(
            coord: coord,
            isPlace: false,
            mapView: mapView,
            onTap: { messages in
                // 메시지가 2개 이상일 때만 콜백 실행 (스택 펼치기)
                if messages.count >= 2 {
                    onTapNoPlace?(messages)
                }
            }
        )
    }

    /// 단일 마커가 없으면 생성하거나 있으면 재사용하고,
    /// 메시지 상태에 따라 아이콘을 비동기로 렌더링하여 갱신합니다.
    /// (메시지가 없으면 markerType이 nil이므로 아이콘 갱신 없이 종료됩니다.)
    private func updateMarker(
        coord: Coordinate,
        isPlace: Bool,
        mapView: NMFMapView,
        onTap: @escaping ([Message]) -> Void
    ) {
        // 마커 식별 키 생성
        let key = MarkerGroupKey(coordinate: coord, isPlace: isPlace)

        AppLog.debug("updateMarker key=\(key) count(place)=\(placeMessagesByCoord[coord]?.count ?? 0) count(noPlace)=\(noPlaceMessagesByCoord[coord]?.count ?? 0)", category: .location)

        // 1. 기존 마커가 있다면 그대로 쓰고, 없으면 새로 만들기
        let marker: NMFMarker
        if let existing = markers[key] {
            marker = existing
        } else {
            marker = createMarker(at: coord, mapView: mapView)
            markers[key] = marker
        }

        // 2. 메시지 조회 (최신 displayLimit개만)
        let messagesInCoord = isPlace ? placeMessagesByCoord[coord] : noPlaceMessagesByCoord[coord]
        let messages = Array((messagesInCoord ?? []).suffix(displayLimit))

        // 3. MarkerType 결정 (메시지가 없으면 nil -> 마커 생성 안 함)
        guard let markerType = MarkerType.from(messages: messages, isPlace: isPlace) else {
            removeMarker(for: key)
            return
        }

        // 4. 탭 핸들러 등록 (위에서 만든 마커 재사용)
        // - 탭 시점의 최신 메시지를 조회하여 콜백에 전달
        marker.touchHandler = { [weak self] _ in
            guard let self else { return true }
            let currentSource = isPlace ? self.placeMessagesByCoord[coord] : self.noPlaceMessagesByCoord[coord]
            onTap(currentSource ?? [])
            return true
        }

        // 5. 초기 이미지 렌더 (key 기준 검증 + Task 누적 방지)
        scheduleInitialRender(for: key, marker: marker, markerType: markerType)

        // 6. 회전 애니메이션 상태 등록 (rotatingBubble 또는 stackBubble인 경우)
        switch markerType {
        case .rotatingBubble, .stackBubble:
            let messagesProvider: () -> [Message] = { [weak self] in
                guard let self else { return [] }
                let source = isPlace ? self.placeMessagesByCoord[coord] : self.noPlaceMessagesByCoord[coord]
                return Array((source ?? []).suffix(self.displayLimit))
            }

            animationStates[key] = BubbleAnimationState(
                messagesProvider: messagesProvider,
                lastRotationTime: Date().timeIntervalSince1970
            )
        case .singleBubble:
            break
        }
    }

    /// 마커를 지도에서 제거하고 저장소에서 삭제합니다.
    private func removeMarker(for key: MarkerGroupKey) {
        markers[key]?.mapView = nil           // 지도에서 제거
        markers.removeValue(forKey: key)      // 마커 딕셔너리에서 삭제
        animationStates.removeValue(forKey: key)  // 애니메이션 상태 삭제

        renderTasks[key]?.cancel()
        renderTasks.removeValue(forKey: key)

        fadeTasks[key]?.cancel()
        fadeTasks.removeValue(forKey: key)

        hasFadedIn.remove(key)
    }

    /// MarkerType에 맞는 마커를 생성하고 이미지를 설정합니다.
    private func createMarker(
        at coord: Coordinate,
        mapView: NMFMapView
    ) -> NMFMarker {
        let position = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
        return makeMarker(at: position, mapView: mapView)
    }

    private func scheduleInitialRender(
        for key: MarkerGroupKey,
        marker: NMFMarker,
        markerType: MarkerType
    ) {
        // 기존 렌더 작업 취소 (최신만 반영)
        renderTasks[key]?.cancel()

        renderTasks[key] = Task { @MainActor in
            let image: UIImage

            switch markerType {
            case .singleBubble(let message):
                image = await bubbleImageRenderer.renderSingleBubble(message: message)

            case .rotatingBubble(let messages), .stackBubble(let messages):
                guard let first = messages.first else { return }
                image = await bubbleImageRenderer.renderSingleBubble(message: first)
            }

            // 취소되었으면 적용 X
            guard !Task.isCancelled else { return }

            // 아직 이 key의 현재 마커가 이 marker인지 확인
            guard markers[key] === marker else { return }

            if hasFadedIn.contains(key) {
                marker.iconImage = NMFOverlayImage(image: image)
                marker.alpha = 1.0
            } else {
                hasFadedIn.insert(key)
                applyIconWithFade(image, to: marker, key: key)
            }
        }
    }
}

// MARK: - 마커 애니메이션

extension MessageMarkerManager {

    /// 회전 애니메이션 상태를 업데이트합니다.
    ///
    /// MapViewController의 타이머/디스플레이 링크에서 주기적으로(예: 60fps 주기) 호출됩니다.
    /// rotatingBubble / stackBubble 타입(다중 메시지)의 마커들에 대해 애니메이션을 처리합니다.
    ///
    /// ## 애니메이션 흐름
    /// 1. 대기 중 -> rotationInterval(3초) 후 애니메이션 시작
    /// 2. 애니메이션 중 -> animationDuration(1초) 동안 진행
    /// 3. 완료 -> 다음 메시지로 전환, 다시 대기
    func updateAnimations() {
        let currentTime = Date().timeIntervalSince1970

        // 모든 애니메이션 상태를 순회
        for groupKey in animationStates.keys {
            // 상태 조회 (없으면 스킵)
            guard var state = animationStates[groupKey] else { continue }
            // 메시지가 2개 미만이면 애니메이션 불필요
            guard state.messages.count > 1 else { continue }
            // 해당 마커가 없으면 스킵
            guard let marker = markers[groupKey] else { continue }

            if state.isAnimating {
                // 애니메이션 진행 중: 진행률 업데이트
                rotationAnimator.updateAnimation(for: &state, currentTime: currentTime)

                // 현재/다음 메시지로 회전 이미지 렌더링
                if let current = state.currentMessage,
                    let next = state.nextMessage {

                    // 기존 렌더 취소 (프레임 누적 방지)
                    renderTasks[groupKey]?.cancel()

                    renderTasks[groupKey] = Task { @MainActor in
                        // marker는 Task 안에서 다시 가져오도록 하기 (교체될 수 있으므로)
                        guard let marker = self.markers[groupKey] else { return }

                        let image = await bubbleImageRenderer.renderRotatingBubble(
                            current: current,
                            next: next,
                            progress: state.animationProgress
                        )

                        guard !Task.isCancelled else { return }
                        guard self.markers[groupKey] === marker else { return }

                        marker.iconImage = NMFOverlayImage(image: image)
                    }
                }
            } else {
                // 대기 중: 시작 시간 확인 후 애니메이션 시작
                if rotationAnimator.shouldStartAnimation(for: state, currentTime: currentTime) {
                    state.startAnimation(at: currentTime)
                }
            }

            animationStates[groupKey] = state
        }
    }

    private func applyIconWithFade(
        _ image: UIImage,
        to marker: NMFMarker,
        key: MarkerGroupKey,
        duration: TimeInterval = 0.5,
        fps: Double = 60
    ) {
        // 기존 페이드 작업 취소
        fadeTasks[key]?.cancel()

        // 아이콘은 먼저 교체
        marker.iconImage = NMFOverlayImage(image: image)

        // 시작은 투명
        marker.alpha = 0.0

        let totalFrames = max(1, Int(duration * fps))
        let frameNanos = UInt64(1_000_000_000 / fps)

        fadeTasks[key] = Task { @MainActor in
            for i in 0...totalFrames {
                if Task.isCancelled { return }
                marker.alpha = CGFloat(Double(i) / Double(totalFrames))
                try? await Task.sleep(nanoseconds: frameNanos)
            }
            marker.alpha = 1.0
        }
    }
}
