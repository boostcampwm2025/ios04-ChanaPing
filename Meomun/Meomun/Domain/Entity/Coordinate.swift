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

    // 소수점 4자리 정밀도 (약 11m 오차)
    private static let precision: Double = 10_000

    /// 서울 시청
    static let seoulCity: Coordinate = .init(latitude: 37.5665, longitude: 126.9780)

    private var normalizedLatitude: Int {
        Int((latitude * Self.precision))
    }

    private var normalizedLongitude: Int {
        Int((longitude * Self.precision))
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

    /// 메시지 ID 기반으로 결정적인 오프셋이 적용된 좌표 반환
    /// - Parameter messageId: 오프셋 방향을 결정할 메시지 ID
    /// - Returns: 소숫점 5자리가 변경된 새 좌표 (약 1.1m 이동)
    func offset(for messageId: MessageID) -> Coordinate {
        // 메시지 ID 해시값으로 각도 결정 (0~359도)
        let angle = Double(abs(messageId.value.hashValue % 360))
        let radians = angle * .pi / 180

        // 소숫점 5자리 오프셋 (약 1.1m)
        let offsetUnit: Double = 0.00001

        return Coordinate(
            latitude: latitude + offsetUnit * cos(radians),
            longitude: longitude + offsetUnit * sin(radians)
        )
    }
}
