//
//  NearbyMessageDTO.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import Foundation

struct NearbyMessageResponseDTO: Decodable, Identifiable {
    let id: UUID
    let authorId: UUID
    let createdAt: Date
    let content: String
    let latitude: Double
    let longitude: Double
    let place: PlaceDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case createdAt = "created_at"
        case content
        case latitude
        case longitude
        case place

    }
}

extension NearbyMessageResponseDTO {
    func toDomain() -> Message {
        return Message(
            id: MessageID(value: id),
            authorID: UserID(value: authorId),
            createdAt: createdAt,
            content: content,
            coordinate: Coordinate(
                latitude: latitude,
                longitude: longitude
            ),
            placeTag: place.map {
                Place(
                    id: PlaceID(value: $0.placeId),
                    name: $0.name,
                    coordinate: Coordinate(
                        latitude: $0.latitude,
                        longitude: $0.longitude
                    )
                )
            }
        )
    }
}
