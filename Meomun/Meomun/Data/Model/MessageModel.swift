//
//  MessageModel.swift
//  Meomun
//
//  Created by Hayeon Park on 1/27/26.
//

import Foundation
import SwiftData

@Model
final class MessageModel {
    @Attribute(.unique) var id: UUID
    @Attribute(originalName: "created_at") var createdAt: Date
    var content: String
    var latitude: Double
    var longitude: Double
    var address: String
    var place: PlaceModel?

    init(
        id: UUID,
        createdAt: Date,
        content: String,
        latitude: Double,
        longitude: Double,
        address: String,
        place: PlaceModel?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.content = content
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.place = place
    }
}

extension MessageModel {
    func toDomain() -> Message {
        .init(
            id: MessageID(value: id),
            createdAt: createdAt,
            content: content,
            coordinate: .init(
                latitude: latitude,
                longitude: longitude
            ),
            address: address,
            placeTag: place?.toDomain()
        )
    }

    func toDTO() -> MessageResponseDTO {
        .init(
            id: id,
            createdAt: createdAt,
            content: content,
            latitude: latitude,
            longitude: longitude,
            address: address,
            place: place?.toDTO()
        )
    }
}
