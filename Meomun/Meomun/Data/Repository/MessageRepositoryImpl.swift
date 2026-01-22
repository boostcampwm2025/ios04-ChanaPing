//
//  MessageRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

final class MessageRepositoryImpl: MessageRepository {
    func createMessage(_ request: CreateMessageRequest) async throws {
        let placeDTO: PlaceDTO? = request.place.map { place in
            PlaceDTO(
                placeId: place.id.value,
                name: place.name,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                address: place.address.isEmpty ? nil : place.address
            )
        }

        let dto: CreateMessageRequestDTO
        if let placeDTO {
            dto = CreateMessageRequestDTO(
                content: request.content,
                latitude: placeDTO.latitude,
                longitude: placeDTO.longitude,
                place: placeDTO
            )
        } else {
            dto = CreateMessageRequestDTO(
                content: request.content,
                latitude: request.coordinate.latitude,
                longitude: request.coordinate.longitude,
                place: placeDTO
            )
        }
    }

    func deleteMessages(messageIDs: [MessageID]) async throws {
        return
    }

    func fetchNearbyMessages(location: Coordinate, limit: Int?) async throws -> [Message] {
        return []
    }

    func fetchPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        return []
    }
}
