//
//  Coordinate.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct Coordinate: Sendable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double

    // 소수점 5자리 정밀도 (약 1.1m 오차)
    private static let precision: Double = 100_000

    private var normalizedLatitude: Int {
        Int((latitude * Self.precision).rounded())
    }

    private var normalizedLongitude: Int {
        Int((longitude * Self.precision).rounded())
    }

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

    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        lhs.normalizedLatitude == rhs.normalizedLatitude &&
        lhs.normalizedLongitude == rhs.normalizedLongitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(normalizedLatitude)
        hasher.combine(normalizedLongitude)
    }
}
