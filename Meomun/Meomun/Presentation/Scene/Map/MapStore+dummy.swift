//
//  MapStore+dummy.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation

extension MapStore {
    // dummy
    func getDummyMessages() -> [Message] {
        // ───────────── 세종문화회관 (회전 그룹) ─────────────
        let place1 = Place(
            id: PlaceID(value: UUID()),
            name: "세종문화회관",
            location: .init(
                latitude: 37.5720,
                longitude: 126.9760
            )
        )

        let group1 = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-3 * 60),
                content: "따뜻한 바람 지나가요🍃",
                location: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-12 * 60),
                content: "공연 리허설 소리 들린다🎻",
                location: .init(latitude: 37.5720, longitude: 126.9760),
                placeTag: place1
            )
        ]

        // ───────────── 광화문광장 (회전 그룹) ─────────────

        let place2 = Place(
            id: PlaceID(value: UUID()),
            name: "광화문광장",
            location: .init(
                latitude: 37.5712,
                longitude: 126.9780
            )
        )

        let group2 = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-8 * 60),
                content: "햇살이 광장 위에 내려앉았어요☀️",
                location: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-50 * 60),
                content: "차분한 아침 분위기 좋다",
                location: .init(latitude: 37.5712, longitude: 126.9780),
                placeTag: place2
            )
        ]

        // ───────────── 경복궁 담벼락 (회전 그룹) ─────────────
        let place3 = Place(
            id: PlaceID(value: UUID()),
            name: "경복궁 담벼락",
            location: .init(
                latitude: 37.5730,
                longitude: 126.9770
            )
        )

        let group3 = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-6 * 60),
                content: "벽에 스치는 바람 소리가 좋다🍃",
                location: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60 * 60),
                content: "발자국 소리가 멀리 울려요",
                location: .init(latitude: 37.5730, longitude: 126.9770),
                placeTag: place3
            )
        ]

        // ═══════════════════════════════════════════════════════════════
        // MARK: - 케이스별 테스트 데이터
        // ═══════════════════════════════════════════════════════════════

        // ───────────── 케이스 1: Place 1개, NoPlace 0개 → 단일 UI ─────────────
        let placeSingle = Place(
            id: PlaceID(value: UUID()),
            name: "덕수궁 돌담길",
            location: .init(latitude: 37.5660, longitude: 126.9750)
        )
        let case1PlaceSingle = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-5 * 60),
                content: "돌담 따라 걷는 발걸음🚶",
                location: .init(latitude: 37.5660, longitude: 126.9750),
                placeTag: placeSingle
            )
        ]

        // ───────────── 케이스 2: Place 0개, NoPlace 1개 → 단일 UI ─────────────
        let case2NoPlaceSingle = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-25 * 60),
                content: "혼자 걷는 골목길이 좋다🌿",
                location: .init(latitude: 37.5680, longitude: 126.9720),
                placeTag: nil
            )
        ]

        // ───────────── 케이스 3: Place 2개 이상, NoPlace 0개 → 로테이션 UI ─────────────
        // (기존 group1, group2, group3이 이 케이스에 해당)

        // ───────────── 케이스 4: Place 0개, NoPlace 2개 이상 → 스택 UI ─────────────
        let stackLocation = Location(latitude: 37.5650, longitude: 126.9800)
        let case4NoPlaceStack = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-7 * 60),
                content: "여기 사람들 많네요👥",
                location: stackLocation,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-30 * 60),
                content: "붐비는 거리 속 작은 평화✨",
                location: stackLocation,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-45 * 60),
                content: "발길 닿는 대로 걸어요👣",
                location: stackLocation,
                placeTag: nil
            )
        ]

        // ───────────── 케이스 5: Place 1개, NoPlace 1개 → 단일, 단일, offset처리 ─────────────
        let placeOffset1 = Place(
            id: PlaceID(value: UUID()),
            name: "청계천 광장",
            location: .init(latitude: 37.5700, longitude: 126.9830)
        )
        let case5Location = Location(latitude: 37.5700, longitude: 126.9830)
        let case5PlaceAndNoPlace = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-4 * 60),
                content: "물소리가 시원해요💧",
                location: case5Location,
                placeTag: placeOffset1
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-35 * 60),
                content: "다리 밑 그늘이 좋네🌉",
                location: case5Location,
                placeTag: nil
            )
        ]

        // ───────────── 케이스 6: Place 2개, NoPlace 1개 → 로테이션, 단일, offset처리 ─────────────
        let placeOffset2 = Place(
            id: PlaceID(value: UUID()),
            name: "종각 보신각",
            location: .init(latitude: 37.5695, longitude: 126.9840)
        )
        let case6Location = Location(latitude: 37.5695, longitude: 126.9840)
        let case6RotationAndSingle = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60),
                content: "종소리 울리는 날🔔",
                location: case6Location,
                placeTag: placeOffset2
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-18 * 60),
                content: "새해맞이 인파 기대돼요🎊",
                location: case6Location,
                placeTag: placeOffset2
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-55 * 60),
                content: "근처 맛집 찾는 중🍜",
                location: case6Location,
                placeTag: nil
            )
        ]

        // ───────────── 케이스 7: Place 1개, NoPlace 2개 이상 → 단일, 스택, offset처리 ─────────────
        let placeOffset3 = Place(
            id: PlaceID(value: UUID()),
            name: "을지로 입구",
            location: .init(latitude: 37.5665, longitude: 126.9850)
        )
        let case7Location = Location(latitude: 37.5665, longitude: 126.9850)
        let case7SingleAndStack = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-9 * 60),
                content: "오래된 건물 사이로🏚️",
                location: case7Location,
                placeTag: placeOffset3
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-22 * 60),
                content: "골목 안 숨은 카페 발견☕️",
                location: case7Location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-48 * 60),
                content: "레트로 감성 가득🎞️",
                location: case7Location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1.5 * 60 * 60),
                content: "인쇄소 잉크 냄새가 나요📰",
                location: case7Location,
                placeTag: nil
            )
        ]

        // ───────────── 케이스 8: Place 2개 이상, NoPlace 2개 이상 → 로테이션, 스택, offset처리 ─────────────
        let placeOffset4 = Place(
            id: PlaceID(value: UUID()),
            name: "명동성당",
            location: .init(latitude: 37.5635, longitude: 126.9870)
        )
        let case8Location = Location(latitude: 37.5635, longitude: 126.9870)
        let case8RotationAndStack = [
            // Place 메시지들 (로테이션)
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-6 * 60),
                content: "고요한 성당 앞 광장⛪️",
                location: case8Location,
                placeTag: placeOffset4
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-28 * 60),
                content: "종탑이 하늘에 닿을 듯🗼",
                location: case8Location,
                placeTag: placeOffset4
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1 * 60 * 60),
                content: "스테인드글라스 빛이 예뻐요🌈",
                location: case8Location,
                placeTag: placeOffset4
            ),
            // NoPlace 메시지들 (스택)
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-14 * 60),
                content: "계단에 앉아 쉬는 중🪜",
                location: case8Location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-38 * 60),
                content: "비둘기들이 모여들어요🐦",
                location: case8Location,
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-2 * 60 * 60),
                content: "저녁 미사 시간이네요🕯️",
                location: case8Location,
                placeTag: nil
            )
        ]

        // ───────────── 기존 단일 버블 (Static) - 참고용 ─────────────
        let statics = [
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-40 * 60),
                content: "벤치에 앉아 잠깐 쉬어요",
                location: .init(latitude: 37.5698, longitude: 126.9775),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-1 * 60 * 60),
                content: "따뜻한 커피 향이 지나간다☕️",
                location: .init(latitude: 37.5704, longitude: 126.9766),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-3 * 60 * 60),
                content: "멀리서 버스 브레이크 소리🚍",
                location: .init(latitude: 37.5718, longitude: 126.9792),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-20 * 60),
                content: "바닥에 그림자가 길게 늘어져요🌒",
                location: .init(latitude: 37.5728, longitude: 126.9756),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-15 * 60),
                content: "누군가 웃는 소리 지나갔다🙂",
                location: .init(latitude: 37.5709, longitude: 126.9786),
                placeTag: nil
            ),
            Message(
                id: MessageID(value: UUID()),
                authorID: UserID(value: UUID()),
                createdAt: Date().addingTimeInterval(-10 * 60 * 60),
                content: "새벽 공기가 차갑고 맑다🌙",
                location: .init(latitude: 37.5692, longitude: 126.9798),
                placeTag: nil
            )
        ]

        return group1 + group2 + group3 + statics
            + case1PlaceSingle
            + case2NoPlaceSingle
            + case4NoPlaceStack
            + case5PlaceAndNoPlace
            + case6RotationAndSingle
            + case7SingleAndStack
            + case8RotationAndStack
    }
}
