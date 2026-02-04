//
//  MessageMarkerDiff.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation
struct MessageMarkerDiff: Equatable {
    let removed: Set<MarkerGroupKey>
    let added: Set<MarkerGroupKey>
    let common: Set<MarkerGroupKey>
    let changed: Set<MarkerGroupKey>
}

enum MessageMarkerDiffCalculator {
    /// B. diff 규칙
    /// - oldKeys/newKeys로 removed/added/common 계산
    /// - common 중 idsHashForKey 다르면 changed
    static func diff(
        old: MessageMarkerSnapshot,
        new: MessageMarkerSnapshot
    ) -> MessageMarkerDiff {

        let oldKeys = old.allKeys
        let newKeys = new.allKeys

        let removed = oldKeys.subtracting(newKeys)
        let added = newKeys.subtracting(oldKeys)
        let common = oldKeys.intersection(newKeys)

        var changed = Set<MarkerGroupKey>()
        changed.reserveCapacity(common.count)

        for key in common {
            let oldHash = idsHashForKey(
                key,
                placeStore: old.placeStore,
                noPlaceStore: old.noPlaceStore
            )

            let newHash = idsHashForKey(
                key,
                placeStore: new.placeStore,
                noPlaceStore: new.noPlaceStore
            )

            if oldHash != newHash {
                changed.insert(key)
            }
        }

        return MessageMarkerDiff(
            removed: removed,
            added: added,
            common: common,
            changed: changed
        )
    }

    private static func idsHashForKey(
        _ key: MarkerGroupKey,
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) -> Int {
        let messages = key.isPlace
        ? placeStore[key.coordinate]
        : noPlaceStore[key.coordinate]

        return idsHash(messages)
    }

    private static func idsHash(_ messages: [Message]?) -> Int {
        guard let messages, !messages.isEmpty else { return 0 }

        var hasher = Hasher()
        for message in messages {
            hasher.combine(message.id)
            hasher.combine(message.createdAt.timeIntervalSince1970)
        }

        return hasher.finalize()
    }
}
