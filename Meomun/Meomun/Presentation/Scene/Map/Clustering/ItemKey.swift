//
//  ItemKey.swift
//  Meomun
//
//  Created by hoon on 1/27/26.
//

import NMapsMap

// MARK: - ClusterItemKey

final class ItemKey: NSObject, NMCClusteringKey {
    let identifier: Int
    let position: NMGLatLng

    init(identifier: Int, position: NMGLatLng) {
        self.identifier = identifier
        self.position = position
    }

    static func markerKey(withIdentifier identifier: Int, position: NMGLatLng) -> ItemKey {
        ItemKey(identifier: identifier, position: position)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ItemKey else { return false }
        if self === object { return true }
        return object.identifier == self.identifier
    }

    override var hash: Int { identifier }

    func copy(with zone: NSZone? = nil) -> Any {
        ItemKey(identifier: identifier, position: position)
    }
}
