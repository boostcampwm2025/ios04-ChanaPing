//
//  SpyMarkerFactory.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@testable import Meomun

final class SpyMarkerFactory: MarkerFactoryProtocol {
    private(set) var makeCount = 0
    private(set) var lastCoord: Coordinate?

    func makeMarker(coordinate: Coordinate) -> MarkerProtocol {
        makeCount += 1
        lastCoord = coordinate
        return SpyMarker()
    }
}
