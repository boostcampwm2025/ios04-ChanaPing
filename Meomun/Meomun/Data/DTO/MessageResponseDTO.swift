//
//  MessageResponseDTO.swift
//  Meomun
//
//  Created by MinwooJe on 1/22/26.
//

import Foundation

struct MessageResponseDTO {
    let id: UUID
    let createdAt: Date
    let content: String
    let latitude: Double
    let longitude: Double
    let address: String
    let place: PlaceDTO?
}

extension MessageResponseDTO {
    func toDomain() -> Message {
        .init(
            id: .init(value: id),
            createdAt: createdAt,
            content: content,
            coordinate: .init(latitude: latitude, longitude: longitude),
            address: address,
            placeTag: place?.toDomain()
        )
    }
}
