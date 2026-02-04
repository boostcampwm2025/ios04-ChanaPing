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
    private(set) var lastMadeMarker: MarkerProtocol?

    func makeMarker(coordinate: Coordinate) -> MarkerProtocol {
        makeCount += 1
        lastCoord = coordinate
        let marker = SpyMarker()
        lastMadeMarker = marker
        return marker
    }
}
