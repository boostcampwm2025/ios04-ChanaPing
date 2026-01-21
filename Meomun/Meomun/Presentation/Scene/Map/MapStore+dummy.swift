//
//  MapStore+dummy.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation

extension MapStore {
    // MARK: - 오프셋 상수
    // 북동쪽 오프셋 (위도 +0.0037, 경도 +0.0044)
    private static let northEastLatOffset: Double = 0.0060
    private static let northEastLngOffset: Double = 0.0060

    // MARK: - 기존 마커 중심 좌표
    private static let originalCenterLat: Double = 37.5710
    private static let originalCenterLng: Double = 126.9775

    // MARK: - 테스트 케이스 기준점 (기존 중심에서 북동쪽 300m)
    private static let testBaseLat: Double = originalCenterLat + northEastLatOffset
    private static let testBaseLng: Double = originalCenterLng + northEastLngOffset

    // MARK: - Public
    func getDummyMessages() -> [Message] {
        return getOriginalDummyMessages() + getTestCaseMessages()
    }

    // MARK: - 기존 더미 데이터
    private func getOriginalDummyMessages() -> [Message] {
        // ───────────── 세종문화회관 (회전 그룹) ─────────────
        let place1 = Place(
            id: PlaceID(value: ""),
            name: "세종문화회관",
            coordinate: .init(
                latitude: 37.5720,
                longitude: 126.9760
            )
        )

        let group1 = [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-3 * 60),
                content: "따뜻한 바람 지나가요🍃",
                coordinate: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-12 * 60),
                content: "공연 리허설 소리 들린다🎻",
                coordinate: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            )
        ]

        // ───────────── 광화문광장 (회전 그룹) ─────────────

        let place2 = Place(
            id: PlaceID(value: ""),
            name: "광화문광장",
            coordinate: .init(
                latitude: 37.5712,
                longitude: 126.9780
            )
        )

        let group2 = [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-8 * 60),
                content: "햇살이 광장 위에 내려앉았어요☀️",
                coordinate: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-50 * 60),
                content: "차분한 아침 분위기 좋다",
                coordinate: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            )
        ]

        // ───────────── 경복궁 담벼락 (회전 그룹) ─────────────
        let place3 = Place(
            id: PlaceID(value: ""),
            name: "경복궁 담벼락",
            coordinate: .init(
                latitude: 37.5730,
                longitude: 126.9770
            )
        )

        let group3 = [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-6 * 60),
                content: "벽에 스치는 바람 소리가 좋다🍃",
                coordinate: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60 * 60),
                content: "발자국 소리가 멀리 울려요",
                coordinate: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            )
        ]

        // ───────────── 기존 단일 버블 (Static) ─────────────
        let statics = [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-40 * 60),
                content: "벤치에 앉아 잠깐 쉬어요",
                coordinate: .init(latitude: 37.5698, longitude: 126.9775),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1 * 60 * 60),
                content: "따뜻한 커피 향이 지나간다☕️",
                coordinate: .init(latitude: 37.5704, longitude: 126.9766),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-3 * 60 * 60),
                content: "멀리서 버스 브레이크 소리🚍",
                coordinate: .init(latitude: 37.5718, longitude: 126.9792),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-20 * 60),
                content: "바닥에 그림자가 길게 늘어져요🌒",
                coordinate: .init(latitude: 37.5728, longitude: 126.9756),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-15 * 60),
                content: "누군가 웃는 소리 지나갔다🙂",
                coordinate: .init(latitude: 37.5709, longitude: 126.9786),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-10 * 60 * 60),
                content: "새벽 공기가 차갑고 맑다🌙",
                coordinate: .init(latitude: 37.5692, longitude: 126.9798),
                placeTag: nil
            )
        ]

        return group1 + group2 + group3 + statics
    }
}

// MARK: - 케이스별 테스트 데이터 (기존 중심에서 북동쪽 300m, 3x3 그리드 배치)

extension MapStore {
    private func getTestCaseMessages() -> [Message] {
        return getCase1Messages()
            + getCase2Messages()
            + getCase3Messages()
            + getCase4Messages()
            + getCase5Messages()
            + getCase6Messages()
            + getCase7Messages()
            + getCase8Messages()
    }

    // MARK: - 케이스 1: Place 1개, NoPlace 0개 → 단일 UI
    // 위치: 그리드 (0, 0) - 좌상단
    private func getCase1Messages() -> [Message] {
        let lat = Self.testBaseLat
        let lng = Self.testBaseLng

        let place = Place(
            id: .init(value: ""),
            name: "[Case1] Place1 NoPlace0",
            coordinate: .init(latitude: lat, longitude: lng)
        )

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-5 * 60),
                content: "[Case1] Place 1개만 있는 단일 UI",
                coordinate: .init(latitude: lat, longitude: lng),
                placeTag: place
            )
        ]
    }

    // MARK: - 케이스 2: Place 0개, NoPlace 1개 → 단일 UI
    // 위치: 그리드 (0, 1) - 상단 중앙
    private func getCase2Messages() -> [Message] {
        let lat = Self.testBaseLat
        let lng = Self.testBaseLng + 0.0008

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-25 * 60),
                content: "[Case2] NoPlace 1개만 있는 단일 UI",
                coordinate: .init(latitude: lat, longitude: lng),
                placeTag: nil
            )
        ]
    }

    // MARK: - 케이스 3: Place 2개 이상, NoPlace 0개 → 로테이션 UI
    // 위치: 그리드 (0, 2) - 우상단
    private func getCase3Messages() -> [Message] {
        let lat = Self.testBaseLat
        let lng = Self.testBaseLng + 0.0016

        let place = Place(
            id: .init(value: ""),
            name: "[Case3] Place2+ NoPlace0",
            coordinate: .init(latitude: lat, longitude: lng)
        )

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-3 * 60),
                content: "[Case3] Place 로테이션 메시지 1",
                coordinate: .init(latitude: lat, longitude: lng),
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-10 * 60),
                content: "[Case3] Place 로테이션 메시지 2",
                coordinate: .init(latitude: lat, longitude: lng),
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-20 * 60),
                content: "[Case3] Place 로테이션 메시지 3",
                coordinate: .init(latitude: lat, longitude: lng),
                placeTag: place
            )
        ]
    }

    // MARK: - 케이스 4: Place 0개, NoPlace 2개 이상 → 스택 UI
    // 위치: 그리드 (1, 0) - 좌측 중앙
    private func getCase4Messages() -> [Message] {
        let lat = Self.testBaseLat - 0.0006
        let lng = Self.testBaseLng
        let location = Coordinate(latitude: lat, longitude: lng)

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-7 * 60),
                content: "[Case4] NoPlace 스택 메시지 1",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-30 * 60),
                content: "[Case4] NoPlace 스택 메시지 2",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-45 * 60),
                content: "[Case4] NoPlace 스택 메시지 3",
                coordinate: location,
                placeTag: nil
            )
        ]
    }

    // MARK: - 케이스 5: Place 1개, NoPlace 1개 → 단일, 단일, offset처리
    // 위치: 그리드 (1, 1) - 중앙
    private func getCase5Messages() -> [Message] {
        let lat = Self.testBaseLat - 0.0006
        let lng = Self.testBaseLng + 0.0008
        let location = Coordinate(latitude: lat, longitude: lng)

        let place = Place(
            id: .init(value: ""),
            name: "[Case5] Place1 NoPlace1",
            coordinate: location
        )

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-4 * 60),
                content: "[Case5] Place 단일 메시지",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-35 * 60),
                content: "[Case5] NoPlace 단일 메시지 (offset)",
                coordinate: location,
                placeTag: nil
            )
        ]
    }

    // MARK: - 케이스 6: Place 2개, NoPlace 1개 → 로테이션, 단일, offset처리
    // 위치: 그리드 (1, 2) - 우측 중앙
    private func getCase6Messages() -> [Message] {
        let lat = Self.testBaseLat - 0.0006
        let lng = Self.testBaseLng + 0.0016
        let location = Coordinate(latitude: lat, longitude: lng)

        let place = Place(
            id: .init(value: ""),
            name: "[Case6] Place2 NoPlace1",
            coordinate: location
        )

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60),
                content: "[Case6] Place 로테이션 1",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-18 * 60),
                content: "[Case6] Place 로테이션 2",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-55 * 60),
                content: "[Case6] NoPlace 단일 (offset)",
                coordinate: location,
                placeTag: nil
            )
        ]
    }

    // MARK: - 케이스 7: Place 1개, NoPlace 2개 이상 → 단일, 스택, offset처리
    // 위치: 그리드 (2, 0) - 좌하단
    private func getCase7Messages() -> [Message] {
        let lat = Self.testBaseLat - 0.0012
        let lng = Self.testBaseLng
        let location = Coordinate(latitude: lat, longitude: lng)

        let place = Place(
            id: .init(value: ""),
            name: "[Case7] Place1 NoPlace2+",
            coordinate: location
        )

        return [
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-9 * 60),
                content: "[Case7] Place 단일 메시지",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-22 * 60),
                content: "[Case7] NoPlace 스택 1 (offset)",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-48 * 60),
                content: "[Case7] NoPlace 스택 2 (offset)",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1.5 * 60 * 60),
                content: "[Case7] NoPlace 스택 3 (offset)",
                coordinate: location,
                placeTag: nil
            )
        ]
    }

    // MARK: - 케이스 8: Place 2개 이상, NoPlace 2개 이상 → 로테이션, 스택, offset처리
    // 위치: 그리드 (2, 1) - 하단 중앙
    private func getCase8Messages() -> [Message] {
        let lat = Self.testBaseLat - 0.0012
        let lng = Self.testBaseLng + 0.0008
        let location = Coordinate(latitude: lat, longitude: lng)

        let place = Place(
            id: .init(value: ""),
            name: "[Case8] Place2+ NoPlace2+",
            coordinate: location
        )

        return [
            // Place 메시지들 (로테이션)
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-6 * 60),
                content: "[Case8] Place 로테이션 1",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-28 * 60),
                content: "[Case8] Place 로테이션 2",
                coordinate: location,
                placeTag: place
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1 * 60 * 60),
                content: "[Case8] Place 로테이션 3",
                coordinate: location,
                placeTag: place
            ),
            // NoPlace 메시지들 (스택)
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-14 * 60),
                content: "[Case8] NoPlace 스택 1 (offset)",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-38 * 60),
                content: "[Case8] NoPlace 스택 2 (offset)",
                coordinate: location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60 * 60),
                content: "[Case8] NoPlace 스택 3 (offset)",
                coordinate: location,
                placeTag: nil
            )
        ]
    }
}

