//
//  MessageMarkerSnapshotTests.swift
//  MeomunTests
//
//  Created by 지연 on 2/4/26.
//

import Testing
@testable import Meomun
import Foundation

struct MessageMarkerSnapshotTests {

    @Test("placeTag 있는 메시지-스냅샷 생성-장소 좌표(placeTag.coordinate)에 그룹핑된다")
    func build_groupsPlaceMessagesByPlaceCoordinate() throws {
        let placeCoord = DummyMessageFactory.seoulCityHallCoordinate
        let messageCoord = DummyMessageFactory.gangnamStationCoordinate

        let m1 = DummyMessageFactory.placeMessage(createdAt: 1, coordinate: messageCoord)
        let snapshot = MessageMarkerSnapshotBuilder.build(from: [m1])

        #expect(snapshot.placeStore[placeCoord]?.count == 1)
        #expect(snapshot.noPlaceStore.isEmpty == true)

        #expect(snapshot.allKeys.contains(.init(coordinate: placeCoord, isPlace: true)) == true)
    }

    @Test("placeTag 없는 메시지-스냅샷 생성-메시지 좌표(message.coordinate)에 그룹핑된다")
    func build_groupsNoPlaceMessagesByMessageCoordinate() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate

        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let snapshot = MessageMarkerSnapshotBuilder.build(from: [m1])

        #expect(snapshot.noPlaceStore[coord]?.count == 1)
        #expect(snapshot.placeStore.isEmpty == true)

        #expect(snapshot.allKeys.contains(.init(coordinate: coord, isPlace: false)) == true)
    }

    @Test("같은 좌표에 place가 존재-스냅샷 생성-noPlace는 offset 좌표로 저장된다")
    func build_appliesOffsetForNoPlaceWhenPlaceExistsAtSameCoordinate() throws {
        let coord = DummyMessageFactory.seoulCityHallCoordinate

        let placeTag = DummyMessageFactory.makePlace(coordinate: coord)

        let place = DummyMessageFactory.makeMessage(
            coordinate: coord,
            placeTag: placeTag,
            createdAt: Date(timeIntervalSince1970: 1)
        )

        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let noPlace = DummyMessageFactory.makeMessage(
            id: id,
            coordinate: coord,
            placeTag: nil,
            createdAt: Date(timeIntervalSince1970: 2)
        )

        let snapshot = MessageMarkerSnapshotBuilder.build(from: [noPlace, place])

        let expectedOffset = coord.offset(for: MessageID(value: id))
        #expect(snapshot.noPlaceStore[coord] == nil)
        #expect(snapshot.noPlaceStore[expectedOffset]?.count == 1)
    }

    @Test("createdAt 오름차순-스냅샷 생성-각 그룹의 배열이 오래된 순으로 정렬된다")
    func build_sortsByCreatedAtAscendingInsideGroups() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate

        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)

        let snapshot = MessageMarkerSnapshotBuilder.build(from: [m2, m1])
        let list = snapshot.noPlaceStore[coord] ?? []

        #expect(list.count == 2)
        #expect(list[0].createdAt <= list[1].createdAt)
    }
}
