//
//  MessageMarkerManager.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import UIKit

// MARK: - MessageMarkerManager

@MainActor
final class MessageMarkerManager: MarkerAttaching {

    /// 장소 태그가 있는 메시지들 (좌표별로 그룹화)
    private var placeMessagesByCoord: [Coordinate: [Message]] = [:]

    /// 장소 태그가 없는 메시지들 (좌표별로 그룹화)
    private var noPlaceMessagesByCoord: [Coordinate: [Message]] = [:]

    private let markerRegistry: MarkerRegistry

    /// 마커 별 회전 애니메이션 상태 (2개 이상 메시지가 있는 마커만 해당)
    private var animationStates: [MarkerGroupKey: BubbleAnimationState] = [:]

    /// 한 마커에 표시할 최대 메시지 수 (기본값: 10)
    private let displayLimit: Int

    private let renderScheduler: MarkerRenderScheduler

    private var lastRenderedSignature: [MarkerGroupKey: MarkerRenderSignature] = [:]

    // MARK: - Clustering

    private let clusterController: MarkerClusteringControlling

    /// 외부 바인딩(카메라 이벤트에서 모드 전환용)
    private weak var boundMapView: MapViewProtocol?

    // MARK: - Factory

    private let markerFactory: MarkerFactoryProtocol
    private let clustererFactory: ClustererFactoryProtocol

    // MARK: - Dependencies

    private let rotationAnimator: MessageRotationAnimating
    private let bubbleImageRenderer: BubbleImageRendering

    init(
        markerFactory: MarkerFactoryProtocol,
        clustererFactory: ClustererFactoryProtocol,
        rotationAnimator: MessageRotationAnimating,
        bubbleImageRenderer: BubbleImageRendering,
        displayLimit: Int = 10
    ) {
        self.markerFactory = markerFactory
        self.clustererFactory = clustererFactory
        self.rotationAnimator = rotationAnimator
        self.bubbleImageRenderer = bubbleImageRenderer
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

        registry.setAttacher(self)
    }
}

// MARK: - MarkerAttaching

extension MessageMarkerManager {
    /// 클러스터 모드 규칙을 담아 마커를 맵에 붙이거나/떼는 역할을 담당합니다.
    func attach(_ marker: MarkerProtocol, to mapView: MapViewProtocol) {
        // 클러스터 모드면 붙이지 않음
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
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // 바인딩 저장
        boundMapView = mapView

        // 클러스터러 준비
        clusterController.bind(mapView: mapView)

        applySnapshot(
            messages,
            mapView: mapView,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace
        )
    }

    func updateClusterModeIfNeeded(zoomLevel: Double) {
        clusterController.updateModeIfNeeded(zoomLevel: zoomLevel)
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
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // 기존 store 기반 oldKeys
        let oldKeys = makeAllGroupKeys(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord
        )

        let oldSnapshot = MessageMarkerSnapshot(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord,
            allKeys: oldKeys
        )

        let newSnapshot = MessageMarkerSnapshotBuilder.build(from: messages)

        let diff = MessageMarkerDiffCalculator.diff(old: oldSnapshot, new: newSnapshot)

        // 데이터 저장소 최신화
        placeMessagesByCoord = newSnapshot.placeStore
        noPlaceMessagesByCoord = newSnapshot.noPlaceStore

        clusterController.onSnapshotUpdated(
            placeStore: placeMessagesByCoord,
            noPlaceStore: noPlaceMessagesByCoord
        )

        // 지도에서 사라질 마커 제거
        for key in diff.removed {
            removeMarker(for: key)
        }

        // added + changed 업데이트
        for key in diff.added.union(diff.changed) {
            updateMarkersForKey(
                key,
                mapView: mapView,
                onTapPlace: onTapPlace,
                onTapNoPlace: onTapNoPlace
            )
        }
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
    }
}

// MARK: - 마커 생성 및 업데이트

extension MessageMarkerManager {
    /// key 단위로 마커들을 업데이트합니다.
    private func updateMarkersForKey(
        _ key: MarkerGroupKey,
        mapView: MapViewProtocol,
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
        mapView: MapViewProtocol,
        onTapPlace: (([Message]) -> Void)?,
        onTapNoPlace: (([Message]) -> Void)?
    ) {
        // Place가 없고, 기존 place 마커도 없다면 스킵
        if (placeMessagesByCoord[coord]?.isEmpty ?? true)
            && markerRegistry.marker(for: .init(coordinate: coord, isPlace: true)) == nil {
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
            && markerRegistry.marker(for: .init(coordinate: coord, isPlace: false)) == nil {
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
        mapView: MapViewProtocol,
        onTap: @escaping ([Message]) -> Void
    ) {
        // 마커 식별 키 생성
        let key = MarkerGroupKey(coordinate: coord, isPlace: isPlace)

        // 1. 기존 마커가 있다면 그대로 쓰고, 없으면 새로 만들기
        let marker = markerRegistry.getOrCreate(
            key: key,
            coordinate: coord,
            mapView: mapView
        )

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
        marker.setOnTap { [weak self] in
            guard let self else { return }
            let currentSource = isPlace ? self.placeMessagesByCoord[coord] : self.noPlaceMessagesByCoord[coord]
            onTap(currentSource ?? [])
            return
        }

        let decision = MessageMarkerRenderPolicy.decide(
            markerType: markerType,
            messages: messages,
            lastSignature: lastRenderedSignature[key],
            hasFadedIn: renderScheduler.hasFadedIn(key),
            hasAnimationState: animationStates[key] != nil
        )

        switch decision {
        case .skipSameSignature:
            return

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

// MARK: - 다크모드 대응

extension MessageMarkerManager {
    func setColorScheme(_ traitCollection: UITraitCollection) {
        bubbleImageRenderer.setColorScheme(traitCollection)
    }

    /// 지도 위의 마커를 갱신합니다.
    /// trait(라이트 모드, 다크 모드) 변경에 따라 메시지 버블의 렌더링 색 모드를 변경하기 위해 사용합니다.
    func rebuildAllMarkers() {
        for key in markerRegistry.allKeys {
            guard let marker = markerRegistry.marker(for: key) else { continue }

            let messagesInCoord = key.isPlace
            ? placeMessagesByCoord[key.coordinate]
            : noPlaceMessagesByCoord[key.coordinate]
            let messages = Array((messagesInCoord ?? []).suffix(displayLimit))

            guard let type = MarkerType.from(messages: messages, isPlace: key.isPlace) else {
                continue
            }

            renderScheduler.scheduleInitialRender(
                for: key,
                marker: marker,
                markerType: type,
                animationStateProvider: { [weak self] in
                    self?.animationStates[key]
                },
                currentMarkerForKey: { [weak self] in
                    self?.markerRegistry.currentMarker(for: key)
                }
            )
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
        if clusterController.isClusterMode { return }

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
            guard markerRegistry.marker(for: groupKey) != nil else { continue }

            if state.isAnimating {
                // 애니메이션 진행 중: 진행률 업데이트
                rotationAnimator.updateAnimation(for: &state, currentTime: currentTime)

                let current = state.currentMessage
                let next = state.nextMessage
                let progress = state.animationProgress

                // 현재/다음 메시지로 회전 이미지 렌더링
                if let current, let next {
                    renderScheduler.scheduleAnimationRender(
                        for: groupKey,
                        current: current,
                        next: next,
                        progress: progress,
                        currentMarkerForKey: { [weak self] in
                            self?.markerRegistry.currentMarker(for: groupKey)
                        }
                    )
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
}

// 동작 통일성 테스트에서 private인 내부 상태를 확인하기 위한 디버그 전용 getter
// swiftlint:disable identifier_name
#if DEBUG
extension MessageMarkerManager {
    var debug_placeStoreKeys: Set<Coordinate> { Set(placeMessagesByCoord.keys) }
    var debug_noPlaceStoreKeys: Set<Coordinate> { Set(noPlaceMessagesByCoord.keys) }
}
#endif
// swiftlint:enable identifier_name
