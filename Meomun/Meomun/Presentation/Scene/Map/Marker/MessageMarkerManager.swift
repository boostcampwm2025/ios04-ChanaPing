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

private struct MarkerRenderSignature: Hashable {
    enum Kind: Int, Hashable { case single, rotating, stack }

    let kind: Kind
    let firstMessageId: MessageID?      // 초기 아이콘에 쓰는 메시지(=single이면 그거, rotating/stack이면 first)
    let count: Int                  // 표시 대상(messages: suffix(displayLimit)) 개수
    let idsHash: Int                // 메시지 묶음 내용 변화 감지용
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
/// lastRenderedSignature: [마커키: 렌더 시그니처 캐시]
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

    private var lastRenderedSignature: [MarkerGroupKey: MarkerRenderSignature] = [:]

    // MARK: - Clustering

    /// 클러스터가 활성화되는 최대 줌 레벨
    private let clusterMaxZoom: Double = 16

    /// 현재 클러스터 모드 여부
    private var isClusterMode: Bool = false

    /// 클러스터러
    private var clusterer: NMCClusterer<ItemKey>?

    /// 외부 바인딩(카메라 이벤트에서 모드 전환용)
    private weak var boundMapView: NMFMapView?

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
    private func makeMarker(at position: NMGLatLng) -> NMFMarker {
        let marker = NMFMarker(position: position)
        marker.anchor = CGPoint(x: 0.5, y: 1.0)   // 마커 하단 중앙이 좌표 위치
        marker.zIndex = 1000                      // 다른 오버레이보다 위에 표시
        marker.isFlat = false                     // 3D 틸트 시에도 수직 유지

        marker.iconImage = MarkerPlaceholder.overlayImage
        marker.alpha = 0.0

        return marker
    }

    /// 클러스터 모드 규칙을 담아 마커를 맵에 붙이거나/떼는 역할을 담당합니다.
    private func attachMarker(_ marker: NMFMarker, to mapView: NMFMapView) {
        // 클러스터 모드면 붙이지 않음
        guard !isClusterMode else {
            marker.mapView = nil
            return
        }
        marker.mapView = mapView
    }

    private func detachMarker(_ marker: NMFMarker) {
        marker.mapView = nil
    }
}

extension MessageMarkerManager {

    /// 초기 메시지 로딩 (앱 시작 또는 화면 진입 시 호출)
    ///
    /// 기존 상태(place/noPlace/markers) 대비 diff를 계산해 필요한 마커만 갱신합니다.
    /// Place 메시지를 먼저 저장한 후 NoPlace 메시지를 저장하여 좌표 겹침 시 오프셋을 적용합니다.
    ///
    /// - Parameters:
    ///   - onTapPlace: Place 마커 탭 시 콜백 (해당 좌표의 모든 메시지 전달)
    ///   - onTapNoPlace: NoPlace 마커 탭 시 콜백 (메시지 배열 전달)
    func loadMessages(
        _ messages: [Message],
        mapView: NMFMapView,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // 바인딩 저장
        boundMapView = mapView

        // 클러스터러 준비
        setupClustererIfNeeded(mapView: mapView)

        applySnapshot(
            messages,
            mapView: mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )

        updateClusterModeIfNeeded(zoomLevel: mapView.zoomLevel)
    }

    func updateClusterModeIfNeeded(zoomLevel: Double) {
        let shouldCluster = zoomLevel <= clusterMaxZoom

        guard let mapView = boundMapView else {
            isClusterMode = shouldCluster
            return
        }

        if shouldCluster == isClusterMode { return }

        setClusterMode(shouldCluster, mapView: mapView)
    }
}

// MARK: - MarkerGroupKey
private extension MessageMarkerManager {
    func makeAllGroupKeys(
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) -> Set<MarkerGroupKey> {
        var keys = Set<MarkerGroupKey>()
        keys.reserveCapacity(placeStore.count + noPlaceStore.count)

        for coord in placeStore.keys where placeStore[coord]?.isEmpty == false {
            keys.insert(MarkerGroupKey(coordinate: coord, isPlace: true))
        }

        for coord in noPlaceStore.keys where noPlaceStore[coord]?.isEmpty == false {
            keys.insert(MarkerGroupKey(coordinate: coord, isPlace: false))
        }

        return keys
    }
}

// MARK: - Diff
extension MessageMarkerManager {
    private func applySnapshot(
        _ messages: [Message],
        mapView: NMFMapView,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // 0) 기존 store 기반 oldKeys
        let oldKeys = makeAllGroupKeys(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord
        )

        // 1) 새 스토어를 로컬에서 구성
        // - Place 먼저 저장 -> NoPlace 저장(Place 겹치면 offset 적용)
        var newPlace: [Coordinate: [Message]] = [:]
        var newNoPlace: [Coordinate: [Message]] = [:]

        let sorted = messages.sorted { $0.createdAt < $1.createdAt }

        // 1-1) Place
        for message in sorted where message.placeTag != nil {
            let coordinate = message.coordinate
            newPlace[coordinate, default: []].append(message)
        }

        // 1-2) NoPlace (Place가 있는 좌표와 동일하면 offset 적용)
        for message in sorted where message.placeTag == nil {
            let originalCoordinate = message.coordinate
            let displayCoordinate: Coordinate

            if newPlace[originalCoordinate] != nil {
                displayCoordinate = originalCoordinate.offset(for: message.id)
            } else {
                displayCoordinate = originalCoordinate
            }
            newNoPlace[displayCoordinate, default: []].append(message)
        }

        // 2) newKeys
        let newKeys = makeAllGroupKeys(placeStore: newPlace, noPlaceStore: newNoPlace)

        // 3) diff 계산
        let removed = oldKeys.subtracting(newKeys)
        let added = newKeys.subtracting(oldKeys)
        let common = oldKeys.intersection(newKeys)

        // 4) changed 판단
        var changed = Set<MarkerGroupKey>()
        changed.reserveCapacity(common.count)

        for key in common {
            let oldHash = idsHashForKey(
                key,
                placeStore: placeMessagesByCoord,
                noPlaceStore: noPlaceMessagesByCoord
            )

            let newHash = idsHashForKey(
                key,
                placeStore: newPlace,
                noPlaceStore: newNoPlace
            )

            if oldHash != newHash {
                changed.insert(key)
            }
        }

        // 5) 데이터 저장소 최신화
        placeMessagesByCoord = newPlace
        noPlaceMessagesByCoord = newNoPlace

        if isClusterMode {
            syncClusterItemsIfNeeded()
        }

        // 6) 지도에서 사라질 마커 제거
        for key in removed {
            removeMarker(for: key)
        }

        // 7) added + changed 업데이트
        for key in added.union(changed) {
            updateMarkersForKey(
                key,
                mapView: mapView,
                onTapPlace: onTapPlace,
                onTapNoPlace: onTapNoPlace
            )
        }
    }

    private func makeRenderSignature(
        markerType: MarkerType,
        messages: [Message]
    ) -> MarkerRenderSignature {
        let kind: MarkerRenderSignature.Kind
        let firstId: MessageID?

        switch markerType {
        case .singleBubble(let message):
            kind = .single
            firstId = message.id
        case .rotatingBubble(let messages):
            kind = .rotating
            firstId = messages.first?.id
        case .stackBubble(let messages):
            kind = .stack
            firstId = messages.first?.id
        }

        let idsHash = idsHash(messages)

        return MarkerRenderSignature(
            kind: kind,
            firstMessageId: firstId,
            count: messages.count,
            idsHash: idsHash
        )
    }

    private func syncAnimationStateIfNeeded(
        key: MarkerGroupKey,
        markerType: MarkerType,
        coordinate: Coordinate,
        isPlace: Bool
    ) {
        // 회전 애니메이션 상태 정합성 확인 후 업데이트
        switch markerType {
        case .rotatingBubble, .stackBubble:
            if animationStates[key] == nil {
                let messagesProvider: () -> [Message] = { [weak self] in
                    guard let self else { return [] }
                    let source = isPlace
                        ? self.placeMessagesByCoord[coordinate]
                        : self.noPlaceMessagesByCoord[coordinate]
                    return Array((source ?? []).suffix(self.displayLimit))
                }

                animationStates[key] = BubbleAnimationState(
                    messagesProvider: messagesProvider,
                    lastRotationTime: Date().timeIntervalSince1970
                )
            }
        case .singleBubble:
            animationStates.removeValue(forKey: key)
        }
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

        lastRenderedSignature.removeAll()
    }
}

// MARK: - 마커 생성 및 업데이트

extension MessageMarkerManager {
    /// key 단위로 마커들을 업데이트합니다.
    private func updateMarkersForKey(
        _ key: MarkerGroupKey,
        mapView: NMFMapView,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        let coord = key.coordinate

        if key.isPlace {
            updateMarker(coord: coord, isPlace: true, mapView: mapView) { messages in
                let uniquePlaces = Set(messages.compactMap { $0.placeTag })
                if uniquePlaces.count == 1 {
                    onTapPlace?(messages)
                }
            }
        } else {
            updateMarker(coord: coord, isPlace: false, mapView: mapView) { messages in
                onTapNoPlace?(messages)
            }
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
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // Place가 없고, 기존 place 마커도 없다면 스킵
        if (placeMessagesByCoord[coord]?.isEmpty ?? true)
            && markers[.init(coordinate: coord, isPlace: true)] == nil {
            // 아무 동작 X
        } else {
            updateMarker(coord: coord, isPlace: true, mapView: mapView) { messages in
                // Place가 있는 메시지만 필터링하여 전달
                let placeMessages = messages.filter { $0.placeTag != nil }
                guard !placeMessages.isEmpty else { return }
                onTapPlace?(placeMessages)
            }
        }

        // NoPlace가 없고, 기존 noPlace 마커도 없다면 스킵
        if (noPlaceMessagesByCoord[coord]?.isEmpty ?? true)
            && markers[.init(coordinate: coord, isPlace: false)] == nil {
            // 아무 동작 X
        } else {
            updateMarker(coord: coord, isPlace: false, mapView: mapView) { messages in
                onTapNoPlace?(messages)
            }
        }
    }

    /// 단일 마커가 없으면 생성하거나 있으면 재사용하고,
    /// 메시지 상태에 따라 아이콘을 비동기로 렌더링하여 갱신합니다.
    /// MarkerType이 nil이면(메시지 없음) 해당 key의 마커를 제거하고 종료합니다.
    private func updateMarker(
        coord: Coordinate,
        isPlace: Bool,
        mapView: NMFMapView,
        onTap: @escaping ([Message]) -> Void
    ) {
        // 마커 식별 키 생성
        let key = MarkerGroupKey(coordinate: coord, isPlace: isPlace)

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
            lastRenderedSignature.removeValue(forKey: key)
            return
        }

        // 애니메이션 상태 정합성 체크
        syncAnimationStateIfNeeded(
            key: key,
            markerType: markerType,
            coordinate: coord,
            isPlace: isPlace
        )

        // 탭 핸들러 등록 (위에서 만든 마커 재사용)
        // - 탭 시점의 최신 메시지를 조회하여 콜백에 전달
        marker.touchHandler = { [weak self] _ in
            guard let self else { return true }
            let currentSource = isPlace ? self.placeMessagesByCoord[coord] : self.noPlaceMessagesByCoord[coord]
            onTap(currentSource ?? [])
            return true
        }

        // 3-1. 현재 렌더 시그니처 계산
        let signature = makeRenderSignature(markerType: markerType, messages: messages)

        // 3-2. 기존 마커가 있고, 시그니처가 동일하면 아이콘 렌더 스킵
        if markers[key] != nil,
           lastRenderedSignature[key] == signature { return }

        // 시그니처 갱신
        lastRenderedSignature[key] = signature

        // 회전 마커가 이미 운영 중이면 굳이 초기 렌더로 덮지 않기
        if case .rotatingBubble = markerType, animationStates[key] != nil, hasFadedIn.contains(key) {
            return
        }
        if case .stackBubble = markerType, animationStates[key] != nil, hasFadedIn.contains(key) {
            return
        }

        // 4. 초기 이미지 렌더 (key 기준 검증 + Task 누적 방지)
        scheduleInitialRender(for: key, marker: marker, markerType: markerType)
    }

    /// 마커를 지도에서 제거하고 저장소에서 삭제합니다.
    private func removeMarker(for key: MarkerGroupKey) {
        if let marker = markers[key] {
            detachMarker(marker)
        }
        markers.removeValue(forKey: key)      // 마커 딕셔너리에서 삭제
        animationStates.removeValue(forKey: key)  // 애니메이션 상태 삭제

        renderTasks[key]?.cancel()
        renderTasks.removeValue(forKey: key)

        fadeTasks[key]?.cancel()
        fadeTasks.removeValue(forKey: key)

        hasFadedIn.remove(key)

        lastRenderedSignature.removeValue(forKey: key)
    }

    /// MarkerType에 맞는 마커를 생성하고 이미지를 설정합니다.
    private func createMarker(
        at coord: Coordinate,
        mapView: NMFMapView
    ) -> NMFMarker {
        let position = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
        let marker = makeMarker(at: position)

        attachMarker(marker, to: mapView)
        return marker
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
                guard messages.count >= 1 else { return }

                if let state = animationStates[key], state.messages.count >= 1 {
                    let snap = state.messages
                    let current = state.currentMessage ?? snap[0]
                    let next = state.nextMessage ?? snap[min(1, snap.count - 1)]

                    image = await bubbleImageRenderer.renderRotatingBubble(
                        current: current,
                        next: next,
                        progress: state.isAnimating ? state.animationProgress : 0
                    )
                } else {
                    // state가 아직 없거나 준비 전이면 messages로 fallback
                    let current = messages[0]
                    let next = messages[min(1, messages.count - 1)]
                    image = await bubbleImageRenderer.renderRotatingBubble(
                        current: current,
                        next: next,
                        progress: 0
                    )
                }
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
        if isClusterMode { return }

        let currentTime = Date().timeIntervalSince1970

        // 모든 애니메이션 상태를 순회
        for groupKey in animationStates.keys {
            // 상태 조회 (없으면 스킵)
            guard var state = animationStates[groupKey] else { continue }
            // 메시지 변화에 맞춰 currentIndex/flags 보정
            state.syncMessagesKeepingIndex(currentTime: currentTime)
            // 메시지가 2개 미만이면 애니메이션 불필요
            guard state.messages.count > 1 else {
                animationStates[groupKey] = state
                continue
            }
            // 해당 마커가 없으면 스킵
            guard markers[groupKey] != nil else { continue }

            if state.isAnimating {
                // 애니메이션 진행 중: 진행률 업데이트
                rotationAnimator.updateAnimation(for: &state, currentTime: currentTime)

                let current = state.currentMessage
                let next = state.nextMessage
                let progress = state.animationProgress

                // 현재/다음 메시지로 회전 이미지 렌더링
                if let current, let next {

                    // 기존 렌더 취소 (프레임 누적 방지)
                    renderTasks[groupKey]?.cancel()

                    renderTasks[groupKey] = Task { @MainActor in
                        // marker는 Task 안에서 다시 가져오도록 하기 (교체될 수 있으므로)
                        guard let marker = self.markers[groupKey] else { return }

                        let image = await bubbleImageRenderer.renderRotatingBubble(
                            current: current,
                            next: next,
                            progress: progress
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

// MARK: - Clustering

private extension MessageMarkerManager {
    func setupClustererIfNeeded(mapView: NMFMapView) {
        guard clusterer == nil else { return }

        let builder = NMCBuilder<ItemKey>()
        let leafMarkerUpdater = LeafMarkerUpdater()
        let clusterMarkerUpdater = ClusterMarkerUpdater()

        builder.leafMarkerUpdater = leafMarkerUpdater
        builder.clusterMarkerUpdater = clusterMarkerUpdater
        clusterer = builder.build()
    }

    /// 클러스터 모드 ON/OFF 전환
    /// - ON: 기존 개별 마커 숨김 + clusterer를 mapView에 attach
    /// - OFF: clusterer detach + 기존 개별 마커 복원
    func setClusterMode(_ enabled: Bool, mapView: NMFMapView) {
        isClusterMode = enabled

        // 클러스터러가 없으면 sync/addAll/attach가 모두 무의미해지므로 여기서 보장
        setupClustererIfNeeded(mapView: mapView)

        if enabled {
            // 1) 개별 마커 숨김
            for (_, marker) in markers {
                detachMarker(marker)
            }

            // 2) 클러스터러 attach (attach 이후 addAll/clear가 반영되도록 순서 고정)
            clusterer?.mapView = mapView

            // 3) 아이템 동기화
            syncClusterItemsIfNeeded()
        } else {
            // 1) 클러스터 숨김
            clusterer?.mapView = nil

            // 2) 개별 마커 복원
            for (_, marker) in markers {
                attachMarker(marker, to: mapView)
            }
        }
    }

    func syncClusterItemsIfNeeded() {
        guard let clusterer else { return }
        guard isClusterMode else { return }

        // 1) desired 그룹키 수집
        var desiredGroupKeys: [MarkerGroupKey] = []

        for coord in placeMessagesByCoord.keys
        where (placeMessagesByCoord[coord]?.isEmpty ?? true) == false {
            desiredGroupKeys.append(MarkerGroupKey(coordinate: coord, isPlace: true))
        }

        for coord in noPlaceMessagesByCoord.keys
        where (noPlaceMessagesByCoord[coord]?.isEmpty ?? true) == false {
            desiredGroupKeys.append(MarkerGroupKey(coordinate: coord, isPlace: false))
        }

        // 2) cluster item map 구성
        var keyTagMap: [ItemKey: NSObject] = [:]
        keyTagMap.reserveCapacity(desiredGroupKeys.count)

        for groupKey in desiredGroupKeys {
            let coord = groupKey.coordinate
            let position = NMGLatLng(lat: coord.latitude, lng: coord.longitude)
            let id = stableClusterId(for: groupKey)

            let tag: NSObject = groupKey.isPlace ? ClusterItemTag.place : ClusterItemTag.noPlace
            keyTagMap[ItemKey(identifier: id, position: position)] = tag
        }

        clusterer.addAll(keyTagMap)
    }

    func stableClusterId(for groupKey: MarkerGroupKey) -> Int {
        // 1e-7 deg ≈ 1.1cm (offset이 수m 수준이면 절대 안 뭉침)
        let scale = 10_000_000.0

        // lat: -90...+90, lng: -180...+180
        let latQ = Int64((groupKey.coordinate.latitude * scale).rounded())
        let lngQ = Int64((groupKey.coordinate.longitude * scale).rounded())

        // 양수화 (범위 안이면 안전)
        let latShifted = latQ + Int64(90 * Int(scale))    // 0 .. 180*scale
        let lngShifted = lngQ + Int64(180 * Int(scale))   // 0 .. 360*scale

        // latShifted: 최대 1,800,000,000 (31bit)
        // lngShifted: 최대 3,600,000,000 (32bit)
        // [isPlace 1bit | lat 31bit | lng 32bit] = 64bit
        let placeBit: Int64 = groupKey.isPlace ? 1 : 0
        let packed = (placeBit << 63)
        | ((latShifted & 0x7FFF_FFFF) << 32)
        | (lngShifted & 0xFFFF_FFFF)

        return Int(truncatingIfNeeded: packed)
    }
}

// MARK: - Helpers

private extension MessageMarkerManager {
    func idsHash(_ messages: [Message]?) -> Int {
        guard let messages, !messages.isEmpty else { return 0 }

        var hasher = Hasher()
        for message in messages {
            hasher.combine(message.id)
            hasher.combine(message.createdAt.timeIntervalSince1970)
        }

        return hasher.finalize()
    }

    func idsHashForKey(
        _ key: MarkerGroupKey,
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) -> Int {
        let messages = key.isPlace
        ? placeStore[key.coordinate]
        : noPlaceStore[key.coordinate]

        return idsHash(messages)
    }
}
