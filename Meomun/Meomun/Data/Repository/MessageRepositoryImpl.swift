//
//  MessageRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation

final class MessageRepositoryImpl: MessageRepository {
    private let storage: MessageStorage

    // TODO: DI 구현 후 디폴트 파라미터 제거
    init(storage: MessageStorage = MessageSwiftDataStorage.shared) {
        self.storage = storage
    }

    func createMessage(_ request: CreateMessageRequest) async throws {
        AppLog.debug("createMessage 진입", category: .repository)
        AppLog.debug(String(describing: request), category: .repository)
        let placeDTO: PlaceDTO? = request.place.map { place in
            PlaceDTO(
                placeId: place.id.value,
                name: place.name,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                address: place.address
            )
        }

        return try await storage.create(
            for: .init(
                content: request.content,
                latitude: request.coordinate.latitude,
                longitude: request.coordinate.longitude,
                address: request.address,
                place: placeDTO
            )
        )
    }

    func updateMessage(_ request: Message) async throws {
        let placeDTO: PlaceDTO? = request.placeTag.map { place in
            PlaceDTO(
                placeId: place.id.value,
                name: place.name,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                address: place.address
            )
        }

        return try await storage.update(
                for: .init(
                    id: request.id.value,
                    createdAt: request.createdAt,
                    content: request.content,
                    latitude: request.coordinate.latitude,
                    longitude: request.coordinate.longitude,
                    address: request.address,
                    place: placeDTO
                )
            )
    }

    func deleteMessages(messageIDs: [MessageID]) async throws {
        return
    }

    func fetchNearbyMessages(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [Message] {
        try await storage.fetchNearby(at: location, bounds: bounds, limit: limit)
            .map { $0.toDomain() }
    }

    func fetchPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        try await storage.fetchByPlace(at: placeID, limit: limit)
            .map { $0.toDomain() }
    }

    func fetchRecentMessages(page: Int, pageSize: Int) async throws -> [Message] {
        try await storage.fetchRecent(page: page, pageSize: pageSize)
            .map { $0.toDomain() }
    }
}
