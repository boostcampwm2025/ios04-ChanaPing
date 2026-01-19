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
    let placeId: PlaceDTO?

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
            placeTag: (placeId == nil ? nil : placeId?.toDomain())
        )
    }
}
