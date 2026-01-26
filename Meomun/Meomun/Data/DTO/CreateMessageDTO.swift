//
//  CreateMessageDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation

enum CreateMessageRequestError: Error, Equatable {
    case http(code: Int, rawBody: String)
    case persistentCreateFailed
}

struct CreateMessageRequestDTO: Encodable, Equatable {
    let content: String
    let latitude: Double
    let longitude: Double
    let address: String
    let place: PlaceDTO?
}

extension CreateMessageRequestDTO {
    func toModel(placeData: PlaceModel?) -> MessageModel {
        return .init(
            id: UUID(),
            createdAt: .now,
            content: content,
            latitude: latitude,
            longitude: longitude,
            address: address,
            place: placeData
        )
    }
}

struct CreateMessageErrorResponseDTO: Decodable, Equatable {
    let code: String
    let message: String
    let details: Details?

    struct Details: Decodable, Equatable {
        let decision: String?
        let reason: String?
        let labels: [String]?
        let score: Double?
    }
}
