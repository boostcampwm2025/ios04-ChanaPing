//
//  DummyMessageFactory.swift
//  MeomunTests
//
//  Created by MinwooJe on 1/20/26.
//

import Foundation
@testable import Meomun

enum DummyMessageFactory {

    /// 서울 시청 좌표 (기본 테스트 좌표)
    static let seoulCityHallCoordinate = Coordinate(latitude: 37.5666805, longitude: 126.9784147)

    /// 강남역 좌표
    static let gangnamStationCoordinate = Coordinate(latitude: 37.498095, longitude: 127.027610)

    /// 부산 해운대 좌표 (다른 도시 테스트용)
    static let busanHaeundaeCoordinate = Coordinate(latitude: 35.1587514, longitude: 129.1604456)

    // MARK: - Coordinate Factory

    /// 커스텀 좌표 생성
    static func makeCoordinate(latitude: Double, longitude: Double) -> Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    // MARK: - Message Factory

    /// 단일 메시지 생성
    static func makeMessage(
        id: UUID = UUID(),
        content: String = "테스트 메시지",
        coordinate: Coordinate,
        placeTag: Place? = nil,
        address: String = "주소",
        createdAt: Date = Date()
    ) -> Message {
        Message(
            id: MessageID(value: id),
            createdAt: createdAt,
            content: content,
            coordinate: coordinate,
            address: address,
            placeTag: placeTag
        )
    }

    /// 여러 메시지 생성 (동일 좌표)
    static func makeMessages(
        count: Int,
        at coordinate: Coordinate
    ) -> [Message] {
        (0..<count).map { index in
            makeMessage(
                content: "메시지 #\(index + 1)",
                coordinate: coordinate
            )
        }
    }

    // MARK: - Place Factory

    /// 테스트용 장소 생성
    static func makePlace(
        id: String = "test-place-id",
        name: String = "테스트 장소",
        coordinate: Coordinate? = nil,
        address: String = "서울시 중구 세종대로 110"
    ) -> Place {
        Place(
            id: PlaceID(value: id),
            name: name,
            coordinate: coordinate ?? seoulCityHallCoordinate,
            address: address
        )
    }

    // MARK: - Error Factory

    /// 네트워크 에러
    static func makeNetworkError() -> Error {
        NSError(
            domain: "NetworkError",
            code: -1009,
            userInfo: [NSLocalizedDescriptionKey: "인터넷 연결이 없습니다."]
        )
    }

    /// 서버 에러
    static func makeServerError() -> Error {
        NSError(
            domain: "ServerError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "서버 오류가 발생했습니다."]
        )
    }

    // 장소 태그 있는 메시지
    static func placeMessage(
        id: UUID = UUID(),
        createdAt: TimeInterval,
        coordinate: Coordinate
    ) -> Message {
        Self.makeMessage(
            id: id,
            coordinate: coordinate,
            placeTag: makePlace(),
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }

    // 장소 태그 없는 메시지
    static func noPlaceMessage(
        id: UUID = UUID(),
        createdAt: TimeInterval,
        coordinate: Coordinate
    ) -> Message {
        Self.makeMessage(
            id: id,
            coordinate: coordinate,
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }
}
