//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import UIKit

// MARK: - MessageMarkerManager
/// 지도 상의 메시지 마커를 생성/갱신하고, 클러스터 모드 및 버블 애니메이션을 제어합니다.
/// - Snapshot diff 기반으로 마커를 최소 갱신
/// - 클러스터 모드에서는 개별 마커를 숨기고 clusterer에 items를 위임

@MainActor
final class MessageMarkerManager: MarkerAttaching {

    // MARK: - Stores

    /// 장소 태그가 있는 메시지들 (좌표별로 그룹화)
    private var placeMessagesByCoord: [Coordinate: [Message]] = [:]
    /// 장소 태그가 없는 메시지들 (좌표별로 그룹화)
    private var noPlaceMessagesByCoord: [Coordinate: [Message]] = [:]

    // MARK: - Rendering

    /// 좌표/타입별 마커 생명주기 관리(생성/재사용/제거)
    private let markerRegistry: MarkerRegistry
    /// 마커 렌더링 스케줄링(초기 렌더/애니메이션 렌더) 및 task 관리
    private let renderScheduler: MarkerRenderScheduler
    /// 동일 상태에서 불필요한 렌더링을 피하기 위한 render signature 캐시
    private var lastRenderedSignature: [MarkerGroupKey: MarkerRenderSignature] = [:]
    /// 한 마커에 표시할 최대 메시지 수 (기본값: 10)
    private let displayLimit: Int

    // MARK: - Animation

    /// 다중 메시지 마커의 회전 애니메이션 상태
    private var animationStates: [MarkerGroupKey: BubbleAnimationState] = [:]

    // MARK: - Clustering

    /// 줌 레벨에 따라 클러스터 모드 전환 및 clusterer 동기화를 담당
    private let clusterController: MarkerClusteringControlling

    // MARK: - Dependencies

    private let rotationAnimator: MessageRotationAnimating
    private let bubbleImageRenderer: BubbleImageRendering
    private let tapRoutingPolicy: MarkerTapRouting

    // MARK: - Init

    init(
        markerFactory: MarkerFactoryProtocol,
        clustererFactory: ClustererFactoryProtocol,
        rotationAnimator: MessageRotationAnimating,
        bubbleImageRenderer: BubbleImageRendering,
        tapRoutingPolicy: MarkerTapRouting = MarkerTapRoutingPolicy(),
        displayLimit: Int = 10
    ) {
        self.rotationAnimator = rotationAnimator
        self.bubbleImageRenderer = bubbleImageRenderer
        self.tapRoutingPolicy = tapRoutingPolicy
        self.displayLimit = displayLimit

        self.renderScheduler = MarkerRenderScheduler(renderer: bubbleImageRenderer)

        let registry = MarkerRegistry(markerFactory: markerFactory)
        self.markerRegistry = registry

        self.clusterController = MarkerClusterController(
            maxZoom: 16,
            clustererFactory: clustererFactory,
            itemsBuilder: ClusterItemsBuilder(),
            markerRegistry: registry
        )

        // MarkerRegistry는 Attacher를 통해 attach/detach 규칙을 위임받음
        registry.setAttacher(self)
    }
}

// MARK: - MarkerAttaching

extension MessageMarkerManager {

    /// 클러스터 모드에서는 개별 마커를 attach하지 않습니다.
    func attach(_ marker: MarkerProtocol, to mapView: MapViewProtocol) {
        guard !clusterController.isClusterMode else {
            marker.setAttached(to: nil)
            return
        }
        marker.setAttached(to: mapView)
    }

    func detach(_ marker: MarkerProtocol) {
        marker.setAttached(to: nil)
    }
}

// MARK: - Public API

extension MessageMarkerManager {

    func onViewWillAppear(mapView: MapViewProtocol, zoomLevel: Double) {
        clusterController.bind(mapView: mapView)
        clusterController.updateModeIfNeeded(zoomLevel: zoomLevel)
        markerRegistry.attachAll(to: mapView)
    }

    /// 메시지 스냅샷을 적용하여 지도 마커를 최소 갱신합니다.
    /// - 클러스터러 bind 및 클러스터 items 동기화 포함
    func loadMessages(
        _ messages: [Message],
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        applySnapshot(
            messages,
            mapView: mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
    }

    /// 줌 레벨 변경에 따라 클러스터 모드 전환을 시도합니다.
    func updateClusterModeIfNeeded(zoomLevel: Double, mapView: MapViewProtocol) {
        clusterController.updateModeIfNeeded(zoomLevel: zoomLevel)
        markerRegistry.attachAll(to: mapView)
    }
}

// MARK: - Snapshot & Diff

private extension MessageMarkerManager {

    /// old/new snapshot diff를 계산해 removed를 제거하고 added/changed만 갱신합니다.
    func applySnapshot(
        _ messages: [Message],
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        let oldSnapshot = makeCurrentSnapshot()
        let newSnapshot = MessageMarkerSnapshotBuilder.build(from: messages)
        let diff = MessageMarkerDiffCalculator.diff(old: oldSnapshot, new: newSnapshot)

        // Store 최신화
        placeMessagesByCoord = newSnapshot.placeStore
        noPlaceMessagesByCoord = newSnapshot.noPlaceStore

        // Cluster 동기화
        clusterController.onSnapshotUpdated(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord
        )

        // diff 적용
        applyMarkerDiff(
            diff,
            mapView: mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
    }

    func makeCurrentSnapshot() -> MessageMarkerSnapshot {
        let keys = makeAllGroupKeys(placeStore: placeMessagesByCoord, noPlaceStore: noPlaceMessagesByCoord)
        return MessageMarkerSnapshot(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord,
            allKeys: keys
        )
    }

    func applyMarkerDiff(
        _ diff: MessageMarkerDiff,
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        for key in diff.removed {
            removeMarker(for: key)
        }

        for key in diff.added.union(diff.changed) {
            updateMarkersForKey(
                key,
                mapView: mapView,
                onTapPlace: onTapPlace,
                onTapNoPlace: onTapNoPlace
            )
        }
    }

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

// MARK: - Reset

extension MessageMarkerManager {

    /// 모든 데이터를 초기화합니다.
    private func clearAll() {
        let keys = markerRegistry.allKeys

        for key in keys {
            renderScheduler.cancelAllTasks(for: key)
            renderScheduler.resetFadedInState(for: key)
        }

        markerRegistry.removeAll()
        animationStates.removeAll()
        placeMessagesByCoord.removeAll()
        noPlaceMessagesByCoord.removeAll()
        lastRenderedSignature.removeAll()

        clusterController.onSnapshotUpdated(placeStore: [:], noPlaceStore: [:])
    }
}

// MARK: - Marker Create / Update

private extension MessageMarkerManager {

    /// 마커 탭 시점의 최신 메시지를 가져와 TapRoutingPolicy로 라우팅합니다.
    func updateMarkersForKey(
        _ key: MarkerGroupKey,
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        updateMarker(
            coord: key.coordinate,
            isPlace: key.isPlace,
            mapView: mapView
        ) { [weak self] messages in
            guard let self else { return }

            guard let route = self.tapRoutingPolicy.route(
                isPlaceMarker: key.isPlace,
                messages: messages
            ) else { return }

            switch route {
            case .place(messages: let messages): onTapPlace?(messages)
            case .noPlace(messages: let messages): onTapNoPlace?(messages)
            }
        }
    }

    /// 메시지 상태에 따라 아이콘을 비동기로 렌더링하여 갱신합니다.
    /// - MarkerType이 nil이면 해당 key의 마커를 제거하고 종료합니다.
    func updateMarker(
        coord: Coordinate,
        isPlace: Bool,
        mapView: MapViewProtocol,
        onTap: @escaping ([Message]) -> Void
    ) {
        // 마커 식별 키 생성
        let key = MarkerGroupKey(coordinate: coord, isPlace: isPlace)

        // 1) 최신 메시지 계산
        let messages = latestMessages(at: coord, isPlace: isPlace)

        // 2) MarkerType 결정 (메시지 없으면 마커 제거 후 종료)
        guard let markerType = MarkerType.from(messages: messages, isPlace: isPlace) else {
            removeMarker(for: key)
            return
        }

        // 3) 마커 준비 (생성/재사용)
        let marker = markerRegistry.getOrCreate(
            key: key,
            coordinate: coord,
            mapView: mapView
        )

        // 4) 애니메이션 상태 정합성 체크
        syncAnimationStateIfNeeded(
            key: key,
            markerType: markerType,
            coordinate: coord,
            isPlace: isPlace
        )

        // 5) 탭 핸들러
        configureTapHandler(
            marker: marker,
            coord: coord,
            isPlace: isPlace,
            onTap: onTap
        )

        // 6) 렌더링 결정 / 스케줄링
        renderIfNeeded(
            key: key,
            marker: marker,
            markerType: markerType,
            messages: messages
        )
    }

    func latestMessages(at coord: Coordinate, isPlace: Bool) -> [Message] {
        let source = isPlace ? placeMessagesByCoord[coord] : noPlaceMessagesByCoord[coord]
        return Array((source ?? []).suffix(displayLimit))
    }

    func configureTapHandler(
        marker: MarkerProtocol,
        coord: Coordinate,
        isPlace: Bool,
        onTap: @escaping ([Message]) -> Void
    ) {
        marker.setOnTap { [weak self] in
            guard let self else { return }
            let currentSource = isPlace ? self.placeMessagesByCoord[coord] : self.noPlaceMessagesByCoord[coord]
            onTap(currentSource ?? [])
        }
    }

    func renderIfNeeded(
        key: MarkerGroupKey,
        marker: MarkerProtocol,
        markerType: MarkerType,
        messages: [Message]
    ) {
        let decision = MessageMarkerRenderPolicy.decide(
            markerType: markerType,
            messages: messages,
            lastSignature: lastRenderedSignature[key],
            hasFadedIn: renderScheduler.hasFadedIn(key),
            hasAnimationState: animationStates[key] != nil
        )

        switch decision {
        case .skipSameSignature: return

        case .skipBecauseAnimatingAlready:
            // 시그니처만 갱신
            let signature = MessageMarkerRenderPolicy.makeSignature(
                markerType: markerType,
                messages: messages
            )
            lastRenderedSignature[key] = signature
            return

        case .renderNeeded(signature: let signature):
            // 초기 이미지 렌더
            lastRenderedSignature[key] = signature

            renderScheduler.scheduleInitialRender(
                for: key,
                marker: marker,
                markerType: markerType,
                animationStateProvider: { [weak self] in
                    self?.animationStates[key]
                },
                currentMarkerForKey: { [weak self] in
                    self?.markerRegistry.currentMarker(for: key)
                }
            )
        }
    }

    /// 마커를 지도에서 제거하고 저장소에서 삭제합니다.
    private func removeMarker(for key: MarkerGroupKey) {
        markerRegistry.remove(key: key)
        animationStates.removeValue(forKey: key)
        renderScheduler.cancelAllTasks(for: key)
        renderScheduler.resetFadedInState(for: key)
        lastRenderedSignature.removeValue(forKey: key)
    }
}

// MARK: - Animation State

private extension MessageMarkerManager {
    func syncAnimationStateIfNeeded(
        key: MarkerGroupKey,
        markerType: MarkerType,
        coordinate: Coordinate,
        isPlace: Bool
    ) {
        // 회전 애니메이션 상태 정합성 확인 후 업데이트
        switch markerType {
        case .rotatingBubble, .stackBubble:
            guard animationStates[key] == nil else { return }

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

        case .singleBubble:
            animationStates.removeValue(forKey: key)
        }
    }
}

// MARK: - Animation Tick

extension MessageMarkerManager {

    /// 회전 애니메이션 상태를 업데이트합니다.
    ///
    /// MapViewController의 타이머/디스플레이 링크에서 주기적으로(예: 60fps) 호출됩니다.
    /// rotatingBubble / stackBubble 타입(다중 메시지)의 마커들에 대해 애니메이션을 처리합니다.
    func updateAnimations() {
        if clusterController.isClusterMode { return }

        let currentTime = Date().timeIntervalSince1970
        let keys = Array(animationStates.keys)

        // 모든 애니메이션 상태를 순회
        for key in keys {
            tickAnimation(for: key, currentTime: currentTime)
        }
    }

    private func tickAnimation(for key: MarkerGroupKey, currentTime: TimeInterval) {
        // 상태 조회 (없으면 스킵)
        guard var state = animationStates[key] else { return }

        // 메시지 변화에 맞춰 currentIndex/flags 보정
        state.syncMessagesKeepingIndex(currentTime: currentTime)

        // 메시지가 2개 미만이면 애니메이션 불필요
        guard state.messages.count > 1 else {
            animationStates[key] = state
            return
        }

        // 해당 마커가 없으면 스킵
        guard markerRegistry.marker(for: key) != nil else { return }

        if state.isAnimating {
            // 애니메이션 진행 중: 진행률 업데이트
            rotationAnimator.updateAnimation(for: &state, currentTime: currentTime)

            let current = state.currentMessage
            let next = state.nextMessage
            let progress = state.animationProgress

            // 현재/다음 메시지로 회전 이미지 렌더링
            if let current, let next {
                renderScheduler.scheduleAnimationRender(
                    for: key,
                    current: current,
                    next: next,
                    progress: progress,
                    currentMarkerForKey: { [weak self] in
                        self?.markerRegistry.currentMarker(for: key)
                    }
                )
            }
        } else {
            // 대기 중: 시작 시간 확인 후 애니메이션 시작
            if rotationAnimator.shouldStartAnimation(for: state, currentTime: currentTime) {
                state.startAnimation(at: currentTime)
            }
        }
        animationStates[key] = state
    }
}

// MARK: - Debug

// 동작 통일성 테스트에서 private인 내부 상태를 확인하기 위한 디버그 전용 getter
// swiftlint:disable identifier_name
#if DEBUG
extension MessageMarkerManager {
    var debug_placeStoreKeys: Set<Coordinate> { Set(placeMessagesByCoord.keys) }
    var debug_noPlaceStoreKeys: Set<Coordinate> { Set(noPlaceMessagesByCoord.keys) }
}
#endif
// swiftlint:enable identifier_name
