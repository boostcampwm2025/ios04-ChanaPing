//
//  MessageMarkerSnapshot.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

/// 마커 그룹핑 결과(Place/NoPlace store) + key 집합
struct MessageMarkerSnapshot: Equatable {
    let placeStore: [Coordinate: [Message]]
    let noPlaceStore: [Coordinate: [Message]]
    let allKeys: Set<MarkerGroupKey>
}

/// 그룹핑 규칙만 담당 (UIKit/Map/Task 없음)
enum MessageMarkerSnapshotBuilder {

    /// A. 스냅샷/그룹핑 규칙
    /// - placeTag 있는 메시지는 placeTag.coordinate 기준으로 그룹핑
    /// - placeTag 없는 메시지는 message.coordinate 기준
    ///   - 단, 같은 좌표에 place 그룹이 있으면 coordinate.offset(for: message.id)로 저장
    /// - createdAt 오름차순 정렬 후 append
    static func build(from messages: [Message]) -> MessageMarkerSnapshot {

        var newPlace: [Coordinate: [Message]] = [:]
        var newNoPlace: [Coordinate: [Message]] = [:]

        let sorted = messages.sorted { $0.createdAt < $1.createdAt }

        // 1) Place
        for message in sorted where message.placeTag != nil {
            guard let coordinate = message.placeTag?.coordinate else { continue }
            newPlace[coordinate, default: []].append(message)
        }

        // 2) NoPlace (Place가 있는 좌표와 동일하면 offset 적용)
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

        let keys = makeAllGroupKeys(placeStore: newPlace, noPlaceStore: newNoPlace)

        return MessageMarkerSnapshot(
            placeStore: newPlace,
            noPlaceStore: newNoPlace,
            allKeys: keys
        )
    }

    private static func makeAllGroupKeys(
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
