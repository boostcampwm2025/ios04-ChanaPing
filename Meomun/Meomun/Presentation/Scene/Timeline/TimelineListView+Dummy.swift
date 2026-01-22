//
//  TimelineListView+Dummy.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import Foundation

extension TimelineListView {
    static func getTimelineDummyMessages() -> [Message] {
        let messages: [Message] = [
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-7 * 60),
                    content: "[Case4] NoPlace 스택 메시지 1",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-300 * 60),
                    content: "그대의 마음 뒤흔들면, 포근한 저 바람되어 안아줄게 그댈. 그대는 밤 하늘에 놓인 작은 별 같아요. 매일 밤 마다 나를 찾아와 나의 맘을 흔들어 놓는 가까운듯 먼 그대여",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-45000 * 60),
                    content: "",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-7000 * 60),
                    content: "[Case4] NoPlace 스택 메시지 1",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-30 * 60),
                    content: "[Case4] NoPlace 스택 메시지 2",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-50000 * 60),
                    content: "[Case4] NoPlace 스택 메시지 2",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                ),
                Message(
                    id: MessageID(value: UUID()),
                    createdAt: Date().addingTimeInterval(-450000 * 60),
                    content: "[Case4] NoPlace 스택 메시지 3",
                    coordinate: Coordinate.defaultCoordinate,
                    placeTag: nil
                )
            ]

        return messages
    }
}
