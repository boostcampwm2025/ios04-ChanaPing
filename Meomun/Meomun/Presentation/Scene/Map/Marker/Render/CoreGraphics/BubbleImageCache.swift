//
//  BubbleImageCache.swift
//  Meomun
//
//  Created by MinwooJe on 2/5/26.
//

import UIKit

/// 베이스 레이어(2종) + 고정 텍스트 레이어(장소명/주소별) 캐시.
/// 베이스는 hasPlaceTag별 최대 2개, 고정 텍스트는 locationText별 N개 상한 + LRU eviction.
actor BubbleImageCache {
    private var baseCache: [Bool: UIImage] = [:]
    private var locationTextCache: [String: UIImage] = [:]
    private var locationTextAccessOrder: [String] = []
    private let maxLocationTextCount: Int

    init(maxLocationTextCount: Int = 50) {
        self.maxLocationTextCount = maxLocationTextCount
    }

    func baseImage(hasPlaceTag: Bool) -> UIImage? {
        baseCache[hasPlaceTag]
    }

    func setBaseImage(_ image: UIImage, hasPlaceTag: Bool) {
        baseCache[hasPlaceTag] = image
    }

    func locationTextImage(locationText: String) -> UIImage? {
        guard let image = locationTextCache[locationText] else { return nil }
        markAsRecentlyUsed(locationText)
        return image
    }

    func setLocationTextImage(_ image: UIImage, locationText: String) {
        if locationTextCache[locationText] != nil {
            markAsRecentlyUsed(locationText)
            locationTextCache[locationText] = image
            return
        }

        while locationTextAccessOrder.count >= maxLocationTextCount, let oldest = locationTextAccessOrder.first {
            locationTextCache.removeValue(forKey: oldest)
            locationTextAccessOrder.removeFirst()
        }
        locationTextCache[locationText] = image
        locationTextAccessOrder.append(locationText)
    }

    func removeAll() {
        baseCache.removeAll()
        locationTextCache.removeAll()
        locationTextAccessOrder.removeAll()
    }
}

extension BubbleImageCache {
    private func markAsRecentlyUsed(_ locationText: String) {
        locationTextAccessOrder.removeAll { $0 == locationText }
        locationTextAccessOrder.append(locationText)
    }
}
