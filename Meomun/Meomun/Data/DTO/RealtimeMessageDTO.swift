//
//  RealtimeMessageDTO.swift
//  Meomun
//
//  Created by 지연 on 1/20/26.
//

import Foundation

struct RealtimeCreatedMessageDTO: Decodable {
    let id: UUID
    let authorId: UUID
    let createdAt: Date
    let content: String
    let latitude: Double
    let longitude: Double
    let placeId: String?

    func toDomain() -> Message {
        Message(
            id: MessageID(value: id),
            authorID: UserID(value: authorId),
            createdAt: createdAt,
            content: content,
            coordinate: Coordinate(
                latitude: latitude,
                longitude: longitude
            ),
            placeTag: (
                placeId == nil ? nil : Place(
                    id: PlaceID(
                        value: placeId!
                    ),
                    name: "",   // place도 같이 받아와야 되는구나..
                    coordinate: Coordinate(
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            )
        )
    }
}
