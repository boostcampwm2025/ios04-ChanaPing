//
//  MessageMarkerManagerTests.swift
//  MeomunTests
//
//  Created by 지연 on 2/4/26.
//

import Testing
import UIKit
import Foundation
@testable import Meomun

@MainActor
struct MessageMarkerManagerTests {

    // MARK: - SUT

    private func makeSUT(
        displayLimit: Int = 10,
        markerFactory: SpyMarkerFactory = .init(),
        clustererFactory: SpyClustererFactory = .init(),
        bubbleRenderer: SpyBubbleRenderer = .init(),
        rotationAnimator: StubRotationAnimator = .init()
    ) -> (
        sut: MessageMarkerManager,
        markerFactory: SpyMarkerFactory,
        clustererFactory: SpyClustererFactory,
        bubbleRenderer: SpyBubbleRenderer
    ) {
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

    private func flushAsync() async {
        await Task.yield()
        await Task.yield()
    }

    // MARK: - A. 스냅샷/그룹핑 규칙

    @Test("placeTag 있음 - loadMessages 호출 - placeTag.coordinate로 그룹핑된다")
    func placeTag있음_로드시_placeTag좌표로그룹핑된다() async {
        let (sut, _, _, _) = makeSUT()
        let mapView = makeMapView()

        let placeCoord = DummyMessageFactory.gangnamStationCoordinate
        let place = DummyMessageFactory.makePlace(coordinate: placeCoord)

        let m1 = DummyMessageFactory.makeMessage(
            coordinate: DummyMessageFactory.busanHaeundaeCoordinate, // message.coordinate는 달라도
            placeTag: place,                                         // placeTag.coordinate로 들어가야 함
            createdAt: Date(timeIntervalSince1970: 10)
        )
        let m2 = DummyMessageFactory.makeMessage(
            coordinate: DummyMessageFactory.seoulCityHallCoordinate,
            placeTag: place,
            createdAt: Date(timeIntervalSince1970: 20)
        )

        sut.loadMessages([m2, m1], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        #expect(sut.debug_placeStoreKeys.contains(placeCoord))
    }

    @Test("place 존재 + noPlace 동일좌표 - loadMessages 호출 - noPlace는 offset 좌표로 저장된다")
    func place존재_noPlace동일좌표_로드시_noPlace는offset좌표로저장된다() async {
        let (sut, _, _, _) = makeSUT()
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let place = DummyMessageFactory.makePlace(coordinate: coord)

        let placeMsg = DummyMessageFactory.makeMessage(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            coordinate: coord,
            placeTag: place,
            createdAt: Date(timeIntervalSince1970: 10)
        )

        let noPlaceId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let noPlaceMsg = DummyMessageFactory.makeMessage(
            id: noPlaceId,
            coordinate: coord,
            placeTag: nil,
            createdAt: Date(timeIntervalSince1970: 20)
        )

        let expectedOffset = coord.offset(for: noPlaceMsg.id)

        sut.loadMessages([placeMsg, noPlaceMsg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        #expect(sut.debug_placeStoreKeys.contains(coord))
        #expect(sut.debug_noPlaceStoreKeys.contains(expectedOffset))
        #expect(sut.debug_noPlaceStoreKeys.contains(coord) == false)
    }

    @Test("createdAt 오름차순 정렬 + displayLimit=2 - loadMessages 호출 - 렌더링은 최신 2개 기준으로 발생한다")
    func createdAt정렬_displayLimit적용_로드시_최신N개만렌더링된다() async {
        let bubbleRenderer = SpyBubbleRenderer()
        let (sut, _, _, renderer) = makeSUT(displayLimit: 2, bubbleRenderer: bubbleRenderer)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate

        // 3개를 같은 coord에 넣어서 rotating/stack 유도 가능
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 20, coordinate: coord)
        let m3 = DummyMessageFactory.noPlaceMessage(createdAt: 30, coordinate: coord)

        sut.loadMessages([m2, m3, m1], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        // displayLimit=2라서 실제 messages는 2개 -> rotatingBubble 렌더 1회는 발생해야 함(초기)
        #expect(renderer.rotatingCount >= 1)
    }

    // MARK: - B. diff 규칙

    @Test("removed 발생 - loadMessages(빈 배열) 호출 - 마커가 제거되고 markerCount가 0이 된다")
    func removed발생_빈스냅샷적용시_마커가제거된다() async {
        let markerFactory = SpyMarkerFactory()
        let (sut, _, _, _) = makeSUT(markerFactory: markerFactory)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        #expect(sut.debug_markerCount == 1)

        sut.loadMessages([], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()
        #expect(sut.debug_markerCount == 0)
    }

    @Test("common + idsHash 동일 - loadMessages 반복 - updateMarkersForKey가 사실상 스킵되어 마커 재생성이 없다")
    func 동일스냅샷반복_적용시_마커재생성이없다() async {
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

    @Test("common + idsHash 변경 - loadMessages 호출 - changed로 판단되어 렌더링이 다시 발생한다")
    func 동일키_idsHash변경_적용시_렌더링이다시발생한다() async {
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

        // createdAt 변경 -> idsHash에 createdAt이 포함되어 있으므로 changed가 되어야 함
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

    // MARK: - C. 렌더 스킵 규칙

    @Test("MarkerRenderSignature 동일 - loadMessages 반복 - BubbleRenderer 호출 카운트가 증가하지 않는다")
    func 시그니처동일_반복적용시_렌더링이증가하지않는다() async {
        let bubbleRenderer = SpyBubbleRenderer()
        let (sut, _, _, renderer) = makeSUT(bubbleRenderer: bubbleRenderer)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        let beforeSingle = renderer.singleCount
        let beforeRotating = renderer.rotatingCount

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        #expect(renderer.singleCount == beforeSingle)
        #expect(renderer.rotatingCount == beforeRotating)
    }

    // MARK: - D. 클러스터 모드 전환 규칙

    @Test("zoomLevel <= 16 - updateClusterModeIfNeeded 호출 - cluster ON + clusterer attach + setItems 수행")
    func 줌16이하_update호출시_클러스터가켜지고_attach_setItems가발생한다() async {
        let clustererFactory = SpyClustererFactory()
        let (sut, _, factory, _) = makeSUT(clustererFactory: clustererFactory)
        let mapView = makeMapView()

        let coord1 = DummyMessageFactory.seoulCityHallCoordinate
        let coord2 = DummyMessageFactory.gangnamStationCoordinate

        let p1 = DummyMessageFactory.makePlace(coordinate: coord1)
        let p2 = DummyMessageFactory.makePlace(coordinate: coord2)

        let m1 = DummyMessageFactory.makeMessage(coordinate: coord1, placeTag: p1, createdAt: Date(timeIntervalSince1970: 10))
        let m2 = DummyMessageFactory.makeMessage(coordinate: coord2, placeTag: p2, createdAt: Date(timeIntervalSince1970: 20))

        sut.loadMessages([m1, m2], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16)
        await flushAsync()

        #expect(sut.debug_isClusterMode == true)
        #expect(factory.clusterer.attachHistory.last == true)
        #expect(factory.clusterer.setItemsCount >= 1)
        #expect(factory.clusterer.lastItems.count == 2)
    }

    @Test("cluster ON 상태 + zoomLevel > 16 - updateClusterModeIfNeeded 호출 - cluster OFF + clusterer detach")
    func 클러스터ON상태에서_줌초과_update호출시_클러스터가꺼지고_detach된다() async {
        let clustererFactory = SpyClustererFactory()
        let (sut, _, factory, _) = makeSUT(clustererFactory: clustererFactory)
        let mapView = makeMapView()

        let coord = DummyMessageFactory.seoulCityHallCoordinate
        let msg = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)

        sut.loadMessages([msg], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16) // ON
        await flushAsync()
        #expect(sut.debug_isClusterMode == true)

        sut.updateClusterModeIfNeeded(zoomLevel: 17) // OFF
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

        let coord = DummyMessageFactory.seoulCityHallCoordinate

        // 2개면 rotating 가능
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 10, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 20, coordinate: coord)

        sut.loadMessages([m1, m2], mapView: mapView, onTapPlace: nil, onTapNoPlace: nil)
        await flushAsync()

        sut.updateClusterModeIfNeeded(zoomLevel: 16)
        await flushAsync()
        #expect(sut.debug_isClusterMode == true)

        let before = renderer.singleCount + renderer.rotatingCount
        sut.updateAnimations()
        await flushAsync()
        let after = renderer.singleCount + renderer.rotatingCount

        #expect(after == before)
    }
}
