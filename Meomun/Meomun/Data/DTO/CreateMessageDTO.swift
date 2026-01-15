//
//  CreateMessageDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

struct CreateMessageRequestDTO: Encodable, Equatable {
    let content: String
    let latitude: Double
    let longitude: Double
    let place: PlaceDTO?
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

enum CreateMessageError: Error, Equatable {
    case blocked(details: CreateMessageErrorResponseDTO)
    case unknown(details: CreateMessageErrorResponseDTO)
    case unauthorized
    case http(code: Int, rawBody: String)
}
