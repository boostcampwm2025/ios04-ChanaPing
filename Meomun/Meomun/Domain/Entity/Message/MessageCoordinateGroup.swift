//
//  MessageCoordinateGroup.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

/// 동일한 좌표(Location)에 존재하는 메시지들을 관리하는 구조체
struct MessageCoordinateGroup {
    private let coordinate: Location

    private(set) var placeMessages: [Message] = []
    private(set) var noPlaceMessages: [Message] = []
    private(set) var countByPlace: [Place: Int] = [:]

    var isEmpty: Bool {
        placeMessages.isEmpty && noPlaceMessages.isEmpty
    }

    init(coordinate: Location) {
        self.coordinate = coordinate
    }

    mutating func append(_ message: Message) {
        if let place = message.placeTag {
            placeMessages.append(message)
            // 최신순 정렬 (내림차순)
            placeMessages.sort { $0.createdAt > $1.createdAt }
            countByPlace[place, default: 0] += 1
        } else {
            noPlaceMessages.append(message)
            // 최신순 정렬 (내림차순)
            noPlaceMessages.sort { $0.createdAt > $1.createdAt }
        }
    }

    mutating func remove(_ message: Message) {
        if let place = message.placeTag {
            placeMessages.removeAll { $0.id == message.id }
            countByPlace[place, default: 0] -= 1
            if countByPlace[place] == 0 {
                countByPlace.removeValue(forKey: place)
            }
        } else {
            noPlaceMessages.removeAll { $0.id == message.id }
        }
    }
}

// MARK: - Coordinate

extension MessageCoordinateGroup {
    /// Place 메시지들의 표시 좌표 (원본 좌표)
    func getPlaceCoordinate() -> Location {
        return coordinate
    }

    /// NoPlace 메시지들의 표시 좌표
    /// Place 메시지와 함께 표시될 경우 Offset을 적용하여 겹침을 방지합니다.
    func getNoPlaceCoordinate() -> Location {
        guard !placeMessages.isEmpty else { return coordinate }

        // 소수점 5번째 자리 변경 (약 1.1m)
        // 화면상 겹침 방지를 위해 약간의 오프셋 적용
        let offset: Double = 0.00005
        return Location(
            latitude: coordinate.latitude - offset,
            longitude: coordinate.longitude + offset
        )
    }
}
