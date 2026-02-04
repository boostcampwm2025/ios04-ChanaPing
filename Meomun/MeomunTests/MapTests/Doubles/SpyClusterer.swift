//
//  SpyClusterer.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@testable import Meomun
import Foundation

final class SpyClusterer: ClustererProtocol {
    private(set) var attachHistory: [Bool] = []
    private(set) var setItemsCount = 0
    private(set) var clearCount = 0
    private(set) var lastItems: [ClusterItem] = []

    func attach(to mapView: MapViewProtocol?) {
        attachHistory.append(mapView != nil)
    }

    func setItems(_ items: [ClusterItem]) {
        setItemsCount += 1
        lastItems = items
    }

    func clear() {
        clearCount += 1
        lastItems = []
    }
}
