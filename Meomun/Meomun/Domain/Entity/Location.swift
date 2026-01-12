//
//  Location.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

struct Location: Sendable {
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
}

extension Location: Equatable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.normalizedLatitude == rhs.normalizedLatitude &&
        lhs.normalizedLongitude == rhs.normalizedLongitude
    }
}

extension Location: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(normalizedLatitude)
        hasher.combine(normalizedLongitude)
    }
}
