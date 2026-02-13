//
//  MessageMarkerManagerTests.swift
//  MeomunTests
//
//  Updated for refactored architecture
//

import Testing
import UIKit
import Foundation
@testable import Meomun

@MainActor
struct MessageMarkerManagerTests {

    // MARK: - Helpers

    private func makeSUT(
        displayLimit: Int = 10,
        markerFactory: SpyMarkerFactory? = nil,
        clustererFactory: SpyClustererFactory? = nil,
        bubbleRenderer: SpyBubbleRenderer? = nil,
        rotationAnimator: StubRotationAnimator? = nil
    ) -> (
        sut: MessageMarkerManager,
        markerFactory: SpyMarkerFactory,
        clustererFactory: SpyClustererFactory,
        bubbleRenderer: SpyBubbleRenderer
    ) {
        let markerFactory = markerFactory ?? SpyMarkerFactory()
        let clustererFactory = clustererFactory ?? SpyClustererFactory()
        let bubbleRenderer = bubbleRenderer ?? SpyBubbleRenderer()
        let rotationAnimator = rotationAnimator ?? StubRotationAnimator()

        let sut = MessageMarkerManager(
            markerFactory: markerFactory,
            clustererFactory: clustererFactory,
            rotationAnimator: rotationAnimator,
            bubbleImageRenderer: bubbleRenderer,
            displayLimit: displayLimit
        )
        return (sut, markerFactory, clustererFactory, bubbleRenderer)
    }

    private func makeMapView() -> MapViewProtocol { SpyMapView() }

    /// async 렌더/스케줄러가 한 번 돌도록
    private func flushAsync() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }

    // MARK: - A. Manager orchestration (marker lifecycle)

    @Test("loadMessages 호출 - 마커가 생성된다 (factory.makeCount 증가)")
    func loadMessages_createsMarkers() async {
        let markerFactory = SpyMarkerFactory()
        let (sut, factory, _, _) = makeSUT(markerFactory: markerFactory)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        #expect(factory.makeCount == 1)
    }

    @Test("removed 발생 - loadMessages(빈 배열) 호출 - 기존 마커가 제거된다 (marker icon render도 더 이상 발생하지 않음)")
    func loadMessages_empty_removesMarkers() async {
        let markerFactory = SpyMarkerFactory()
        let bubbleRenderer = SpyBubbleRenderer()
        let (sut, factory, _, renderer) = makeSUT(
            markerFactory: markerFactory,
            bubbleRenderer: bubbleRenderer
        )
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        #expect(factory.makeCount == 1)

        let before = renderer.singleCount + renderer.rotatingCount

        sut.loadMessages([], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        // 추가 생성이 없어야 함
        #expect(factory.makeCount == 1)

        // (선택) 빈 스냅샷 적용 이후 렌더가 더 증가하지 않는지
        let after = renderer.singleCount + renderer.rotatingCount
        #expect(after == before)
    }

    @Test("동일 스냅샷 반복 적용 - 마커 재생성이 없다 (factory.makeCount 유지)")
    func applyingSameSnapshot_doesNotRecreateMarker() async {
        let markerFactory = SpyMarkerFactory()
        let (sut, factory, _, _) = makeSUT(markerFactory: markerFactory)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        #expect(factory.makeCount == 1)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        #expect(factory.makeCount == 1)
    }

    @Test("changed 케이스 - loadMessages 호출 - 렌더링이 다시 발생한다 (renderer count 증가)")
    func changedSnapshot_triggersRerender() async {
        let bubbleRenderer = SpyBubbleRenderer()
        let (sut, _, _, renderer) = makeSUT(bubbleRenderer: bubbleRenderer)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate

        let id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let msg_v1 = DummyMessageFactory.makeMessage(
            id: id,
            coordinate: coord,
            createdAt: Date(timeIntervalSince1970: 10)
        )

        sut.loadMessages([msg_v1], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        let before = renderer.singleCount + renderer.rotatingCount

        let msg_v2 = DummyMessageFactory.makeMessage(
            id: id,
            coordinate: coord,
            createdAt: Date(timeIntervalSince1970: 999)
        )

        sut.loadMessages([msg_v2], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        let after = renderer.singleCount + renderer.rotatingCount

        #expect(after > before)
    }

    // MARK: - B. displayLimit 관련(Manager 레벨에서는 "렌더가 발생했다"까지만)

    @Test("displayLimit=2 + 3개 메시지 - loadMessages 호출 - rotating/stack 렌더가 발생한다(>=1)")
    func displayLimit_appliesAndRenders() async {
        let bubbleRenderer = SpyBubbleRenderer()
        let (sut, _, _, renderer) = makeSUT(displayLimit: 2, bubbleRenderer: bubbleRenderer)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 20, coordinate: coord)
        let m3 = DummyMessageFactory.noPlaceMessage(createdAt: 30, coordinate: coord)

        sut.loadMessages([m2, m3, m1], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        #expect(renderer.rotatingCount >= 1)
    }

    // MARK: - C. Cluster mode orchestration

    @Test("zoomLevel <= 16 - (onViewWillAppear 후) updateClusterModeIfNeeded 호출 - cluster ON + clusterer attach + setItems 수행")
    func 줌16이하_update호출시_클러스터가켜지고_attach_setItems가발생한다() async {
        let clustererFactory = SpyClustererFactory()
        let (sut, _, factory, _) = makeSUT(clustererFactory: clustererFactory)
        let mapView = makeMapView()

        // ✅ bind 먼저
        sut.onViewWillAppear(mapView: mapView, zoomLevel: 17)
        await flushAsync()

        let coord1 = DummyMessageFactory.seoulCityHallCoordinate
        let coord2 = DummyMessageFactory.gangnamStationCoordinate
        let p1 = DummyMessageFactory.makePlace(coordinate: coord1)
        let p2 = DummyMessageFactory.makePlace(coordinate: coord2)

        let m1 = DummyMessageFactory.makeMessage(coordinate: coord1, placeTag: p1, createdAt: Date(timeIntervalSince1970: 10))
        let m2 = DummyMessageFactory.makeMessage(coordinate: coord2, placeTag: p2, createdAt: Date(timeIntervalSince1970: 20))

        sut.loadMessages([m1, m2], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16, mapView: mapView)
        await flushAsync()

        #expect(sut.debug_isClusterMode == true)
        #expect(factory.clusterer.attachHistory.last == true)

        // 구현에 따라 "클러스터 ON 시점"에 setItems가 호출되는 구조여야 정상
        #expect(factory.clusterer.setItemsCount >= 1)
        #expect(factory.clusterer.lastItems.count == 2)
    }

    @Test("cluster ON 상태 + zoomLevel > 16 - (onViewWillAppear 후) updateClusterModeIfNeeded 호출 - cluster OFF + clusterer detach")
    func 클러스터ON상태에서_줌초과_update호출시_클러스터가꺼지고_detach된다() async {
        let clustererFactory = SpyClustererFactory()
        let (sut, _, factory, _) = makeSUT(clustererFactory: clustererFactory)
        let mapView = makeMapView()

        // ✅ bind
        sut.onViewWillAppear(mapView: mapView, zoomLevel: 17)
        await flushAsync()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16, mapView: mapView) // ON
        await flushAsync()
        #expect(sut.debug_isClusterMode == true)
        #expect(factory.clusterer.attachHistory.last == true)

        sut.updateClusterModeIfNeeded(zoomLevel: 17, mapView: mapView) // OFF
        await flushAsync()
        #expect(sut.debug_isClusterMode == false)
        #expect(factory.clusterer.attachHistory.last == false)
    }

    @Test("cluster 모드 - updateAnimations 호출 - BubbleRenderer가 호출되지 않는다")
    func 클러스터모드에서_updateAnimations호출시_렌더링이발생하지않는다() async {
        let bubbleRenderer = SpyBubbleRenderer()
        let clustererFactory = SpyClustererFactory()
        let (sut, _, _, renderer) = makeSUT(clustererFactory: clustererFactory, bubbleRenderer: bubbleRenderer)
        let mapView = makeMapView()

        sut.onViewWillAppear(mapView: mapView, zoomLevel: 17)
        await flushAsync()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 20, coordinate: coord)

        sut.loadMessages([m1, m2], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16, mapView: mapView)
        await flushAsync()
        #expect(sut.debug_isClusterMode == true)

        let before = renderer.singleCount + renderer.rotatingCount
        sut.updateAnimations()
        await flushAsync()
        let after = renderer.singleCount + renderer.rotatingCount

        #expect(after == before)
    }

    // MARK: - D. Tab 전환 복귀 시나리오(재-attach)

    @Test("onViewWillAppear - 기존 마커들이 mapView에 다시 attach된다")
    func onViewWillAppear_reAttachesExistingMarkers() async {
        let markerFactory = SpyMarkerFactory()
        let (sut, _, _, _) = makeSUT(markerFactory: markerFactory)

        let mapView = makeMapView()
        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        // markerFactory가 마지막 marker에 접근 가능해야 함
        guard let marker = markerFactory.lastMadeMarker as? SpyMarker else {
            Issue.record("SpyMarkerFactory.lastMadeMarker가 필요합니다.")
            return
        }

        // 처음 생성 시 attach 되었는지
        #expect(marker.attachedHistory.last == true)

        // (탭 이동을 흉내내기) 일단 detach 한 번 시켜둠
        marker.setAttached(to: nil)
        #expect(marker.attachedHistory.last == false)

        // 다시 화면 등장
        sut.onViewWillAppear(mapView: mapView, zoomLevel: 17)
        await flushAsync()

        // 복귀 시 다시 attach되었는지
        #expect(marker.attachedHistory.last == true)
    }
}
