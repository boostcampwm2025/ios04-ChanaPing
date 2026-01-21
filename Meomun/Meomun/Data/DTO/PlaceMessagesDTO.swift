//
//  PlaceMessagesDTO.swift
//  Meomun
//
//  Created by hoon on 1/15/26.
//

import Foundation

// MARK: - Message

struct PlaceMessageResponseDTO: Decodable, Sendable {
    let id: UUID
    let authorID: UUID
    let createdAt: Date
    let content: String
    let latitude: Double
    let longitude: Double
    let expiresAt: Date
    let deletedAt: Date?
    let place: PlaceDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case authorID = "author_id"
        case createdAt = "created_at"
        case content
        case latitude
        case longitude
        case expiresAt = "expires_at"
        case deletedAt = "deleted_at"
        case place
    }
}

// MARK: - Mapping

extension PlaceMessageResponseDTO {
    func toDomain() -> Message {
        let coordinate = Coordinate(latitude: latitude, longitude: longitude)
        let placeTag = place?.toDomain()

        return Message(
            id: MessageID(value: id),
            createdAt: createdAt,
            content: content,
            coordinate: coordinate,
            placeTag: placeTag
        )
    }
}
