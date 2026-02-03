//
//  MessageSwiftDataStorage+Profiling.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import Foundation

extension Coordinate {
    /// 가산디지털단지역 좌표 (프로파일링용 기본 위치)
    static let gasanDigitalComplex = Coordinate(
        latitude: 37.482167,
        longitude: 126.87725
    )
}

extension MessageStorage {
    /// 프로파일링용 더미 데이터 생성
    ///
    /// - Parameters:
    ///   - markerCount: 생성할 마커(위치) 개수
    ///   - messagesPerMarker: 각 마커에 포함될 메시지 개수
    ///   - center: 더미 데이터가 생성될 중심 좌표
    ///   - radiusKm: 중심 좌표로부터의 반경 (km)
    ///
    /// - Note:
    ///   - 장소 태그는 50% 확률로 추가됩니다 (짝수 인덱스 마커)
    ///   - 같은 마커에 속한 메시지들은 동일한 좌표와 장소 태그를 가집니다
    ///   - 기존 데이터는 자동으로 초기화됩니다
    ///   - 좌표 정밀도(약 11m) 그리드에 양자화하여, 마커가 서로 다른 좌표로 그룹화되도록 보장합니다.
    ///   - 셀 중간값을 사용해 Coordinate의 내림(Int) 정규화와 부동소수점 오차에 따른 그룹핑을 완전히 보장합니다.
    func seedProfilingData(
        markerCount: Int,
        messagesPerMarker: Int = 5,
        center: Coordinate = .gasanDigitalComplex,
        radiusKm: Double = 0.3
    ) async throws {
        // 기존 데이터 초기화
        try await reset()
        AppLog.info("프로파일링 데이터 생성 시작", category: .resource)

        // Coordinate 정밀도(약 11m, 0.0001도) 그리드에 양자화.
        let cellKey = { (normLat: Int, normLng: Int) in normLat * 1_000_000 + normLng }
        var usedCells: Set<Int> = []

        // 셀 중간값(0.00005) 사용 -> Coordinate의 Int(lat*10_000) 내림 시 부동소수점 오차에도 동일 셀로 유지
        let cellMidStep = 0.00005
        // 동심원 배치 후 그리드 양자화 + 중복 제거하여 고유 좌표 배열 생성
        let positions: [(lat: Double, lng: Double)] = (0..<markerCount).map { markerIndex in
            let (latOffset, lngOffset) = circularOffset(
                markerIndex: markerIndex,
                totalMarkers: markerCount,
                radiusKm: radiusKm
            )
            var latQ = (center.latitude + latOffset) * 10_000
            let lngQ = (center.longitude + lngOffset) * 10_000
            var normLat = Int(latQ.rounded())
            let normLng = Int(lngQ.rounded())
            var key = cellKey(normLat, normLng)
            while usedCells.contains(key) {
                latQ += 1
                normLat = Int(latQ.rounded())
                key = cellKey(normLat, normLng)
            }
            usedCells.insert(key)
            return (
                Double(normLat) / 10_000 + cellMidStep,
                Double(normLng) / 10_000 + cellMidStep
            )
        }

        for (markerIndex, position) in positions.enumerated() {
            let markerLat = position.lat
            let markerLng = position.lng

            // 마커 단위로 장소 태그 유무 결정 (짝수 인덱스 마커만 장소 태그 추가)
            let place: PlaceDTO? = if markerIndex % 2 == 0 {
                PlaceDTO(
                    placeId: "profiling_place_\(markerIndex)",
                    name: "프로파일링 장소 \(markerIndex + 1)",
                    latitude: markerLat,
                    longitude: markerLng,
                    address: "프로파일링 주소 \(markerIndex + 1)"
                )
            } else {
                nil
            }

            // 각 마커에 여러 메시지 추가
            for msgIndex in 0..<messagesPerMarker {

                let message = CreateMessageRequestDTO(
                    content: "마커 \(markerIndex + 1) - 메시지 \(msgIndex + 1)",
                    latitude: markerLat,
                    longitude: markerLng,
                    address: "프로파일링 주소 \(markerIndex + 1)",
                    place: place
                )

                try await create(for: message)
            }
        }

        let totalMessages = markerCount * messagesPerMarker
        AppLog.info("✅ 프로파일링 데이터 생성 완료", category: .resource)
        AppLog.info("   - 마커: \(markerCount)개", category: .resource)
        AppLog.info("   - 총 메시지: \(totalMessages)개", category: .resource)
        AppLog.info("   - 마커당 메시지: \(messagesPerMarker)개", category: .resource)
        AppLog.info("   - 장소 태그: 50%", category: .resource)
        AppLog.info("   - 중심: (\(center.latitude), \(center.longitude))", category: .resource)
        AppLog.info("   - 반경: \(radiusKm)km", category: .resource)
    }

    /// 중심 좌표 기준 동심원 배치용 오프셋 (여러 원에 균등 분산, 최대 반경 이내)
    ///
    /// - Parameters:
    ///   - markerIndex: 마커 인덱스 (0부터)
    ///   - totalMarkers: 전체 마커 수
    ///   - radiusKm: 최대 반경 (km)
    /// - Returns: 위도/경도 오프셋 (도 단위)
    private func circularOffset(markerIndex: Int, totalMarkers: Int, radiusKm: Double) -> (lat: Double, lng: Double) {
        guard totalMarkers > 0 else { return (0, 0) }
        // 동심원 개수 (2~5개, 마커 수에 따라 조정)
        let numRings = min(5, max(2, totalMarkers / 4))

        // 이 마커가 속한 원(링) 인덱스
        let ringIndex = markerIndex * numRings / totalMarkers

        // 해당 링 내에서의 순서
        let startOfRing = ringIndex * totalMarkers / numRings
        let endOfRing = (ringIndex + 1) * totalMarkers / numRings
        let indexInRing = markerIndex - startOfRing
        let countInRing = endOfRing - startOfRing

        // 같은 링 위에서 균등 각도
        let angle = countInRing > 0
            ? 2 * Double.pi * Double(indexInRing) / Double(countInRing)
            : 0

        // 링 반경: 중심에 가까운 원부터 (최대 반경 이내)
        let distance = (Double(ringIndex) + 0.5) / Double(numRings) * radiusKm
        let kmToDegree = 0.009
        let latOffset = distance * kmToDegree * cos(angle)
        let lngOffset = distance * kmToDegree * sin(angle)
        
        return (latOffset, lngOffset)
    }
}
