//
//  MessageMarkerDiffTests.swift
//  MeomunTests
//
//  Created by 지연 on 2/4/26.
//

import Testing
@testable import Meomun
import Foundation

struct MessageMarkerDiffTests {

    @Test("oldKeys-newKeys 비교-diff 계산-removed/added/common이 올바르다")
    func diff_computesRemovedAddedCommon() throws {
        let coordA = DummyMessageFactory.seoulCityHallCoordinate
        let coordB = DummyMessageFactory.gangnamStationCoordinate

        let oldMessages = [
            DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coordA)
        ]
        let newMessages = [
            DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coordB)
        ]

        let oldSnap = MessageMarkerSnapshotBuilder.build(from: oldMessages, displayLimit: 10)
        let newSnap = MessageMarkerSnapshotBuilder.build(from: newMessages, displayLimit: 10)

        let diff = MessageMarkerDiffCalculator.diff(old: oldSnap, new: newSnap, displayLimit: 10)

        #expect(diff.removed == [MarkerGroupKey(coordinate: coordA, isPlace: false)])
        #expect(diff.added == [MarkerGroupKey(coordinate: coordB, isPlace: false)])
        #expect(diff.common.isEmpty == true)
        #expect(diff.changed.isEmpty == true)
    }

    @Test("common 키 존재-diff 계산-표시 대상 suffix(displayLimit)가 바뀌면 changed로 잡힌다")
    func diff_marksChangedWhenDisplaySuffixChanges() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let limit = 2

        // old: [m1, m2]
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)

        // new: [m1, m2, m3] => suffix(2)는 [m2, m3]로 변경
        let m3 = DummyMessageFactory.noPlaceMessage(createdAt: 3, coordinate: coord)

        let oldSnap = MessageMarkerSnapshotBuilder.build(from: [m1, m2], displayLimit: limit)
        let newSnap = MessageMarkerSnapshotBuilder.build(from: [m1, m2, m3], displayLimit: limit)

        let diff = MessageMarkerDiffCalculator.diff(old: oldSnap, new: newSnap, displayLimit: limit)

        #expect(diff.common == [MarkerGroupKey(coordinate: coord, isPlace: false)])
        #expect(diff.changed == [MarkerGroupKey(coordinate: coord, isPlace: false)])
        #expect(diff.removed.isEmpty == true)
        #expect(diff.added.isEmpty == true)
    }

    @Test("common 키 존재-diff 계산-표시 대상 suffix(displayLimit)가 동일하면 changed가 아니다")
    func diff_doesNotMarkChangedWhenDisplaySuffixSame() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let limit = 10

        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)

        let oldSnap = MessageMarkerSnapshotBuilder.build(from: [m1, m2], displayLimit: limit)
        let newSnap = MessageMarkerSnapshotBuilder.build(from: [m1, m2], displayLimit: limit)

        let diff = MessageMarkerDiffCalculator.diff(old: oldSnap, new: newSnap, displayLimit: limit)

        #expect(diff.common == [MarkerGroupKey(coordinate: coord, isPlace: false)])
        #expect(diff.changed.isEmpty == true)
        #expect(diff.removed.isEmpty == true)
        #expect(diff.added.isEmpty == true)
    }
}
