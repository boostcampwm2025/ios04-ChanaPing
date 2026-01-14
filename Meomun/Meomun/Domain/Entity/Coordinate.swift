//
//  Coordinate.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct Coordinate: Sendable {
    let latitude: Double
    let longitude: Double

    func distance(to other: Coordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitude1Radians = latitude * .pi / 180
        let latitude2Radians = other.latitude * .pi / 180
        let deltaLatitudeRadians = (other.latitude - latitude) * .pi / 180
        let deltaLongitudeRadians = (other.longitude - longitude) * .pi / 180

        let haversineValue =
        sin(deltaLatitudeRadians / 2) * sin(deltaLatitudeRadians / 2) +
        cos(latitude1Radians) * cos(latitude2Radians) *
        sin(deltaLongitudeRadians / 2) * sin(deltaLongitudeRadians / 2)

        let centralAngle =
        2 * atan2(sqrt(haversineValue), sqrt(1 - haversineValue))

        return earthRadiusMeters * centralAngle
    }
}
