//
//  MessageSwiftDataStorage.swift
//  Meomun
//
//  Created by Hayeon Park on 1/26/26.
//

import SwiftData
import Foundation

actor MessageSwiftDataStorage: MessageStorage {
    static let shared = MessageSwiftDataStorage()

    private var container: ModelContainer?
    private var context: ModelContext {
        guard let container else { fatalError("SwiftDataStorage 구성 실패") }
        return ModelContext(container)
    }

    private init() {}

    func configure(container: ModelContainer) {
        self.container = container
    }

    // TODO: fetchNearby 파라미터 변경 필요
    func fetchNearby(at coordinate: Coordinate, limit: Int?) async throws -> [MessageResponseDTO] {
        var descriptor = FetchDescriptor<MessageModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }

        let results = try context.fetch(descriptor)
        return results.map { $0.toDTO() }
    }

    func fetchByPlace(at placeID: PlaceID, limit: Int?) async throws -> [MessageResponseDTO] {
        let placeIdValue: String? = placeID.value
        var descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { message in
                message.place?.id == placeIdValue
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let limit { descriptor.fetchLimit = limit }

        let results = try context.fetch(descriptor)
        return results.map { $0.toDTO() }
    }

    func fetchRecent(page: Int, pageSize: Int) async throws -> [MessageResponseDTO] {
        var descriptor = FetchDescriptor<MessageModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(0, page) * pageSize

        let results = try context.fetch(descriptor)
        return results.map { $0.toDTO() }
    }

    func create(for message: CreateMessageRequestDTO) async throws {
        let placeData: PlaceModel?
        if let dto = message.place {
            placeData = try fetchOrCreatePlace(dto: dto, context: context)
        } else {
            placeData = nil
        }

        let newMessage = message.toModel(placeData: placeData)

        context.insert(newMessage)
        try context.save()
    }

    func delete(messageID: MessageID) async throws {
        let messageIdValue: UUID = messageID.value
        var descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { $0.id == messageIdValue }
        )
        descriptor.fetchLimit = 1

        if let target = try context.fetch(descriptor).first {
            context.delete(target)
        } else {
            AppLog.warn("삭제할 대상 데이터가 없어요. MessageID : \(messageID)", category: .storage)
        }
    }

    func update(for message: UpdateMessageRequestDTO) async throws {
        let messageId: UUID = message.id
        var descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { $0.id == messageId }
        )
        descriptor.fetchLimit = 1

        guard let target = try context.fetch(descriptor).first else {
            AppLog.warn("수정할 대상 데이터가 없어요. id: \(message.id)", category: .store)
            return
        }

        // Place Upsert
        let placeData: PlaceModel?
        if let dto = message.place {
            placeData = try fetchOrCreatePlace(dto: dto, context: context)
        } else {
            placeData = nil
        }

        target.content = message.content
        target.latitude = message.latitude
        target.longitude = message.longitude
        target.address = message.address
        target.place = placeData

        try context.save()
    }
}

private extension MessageSwiftDataStorage {
    func fetchOrCreatePlace(dto: PlaceDTO, context: ModelContext) throws -> PlaceModel {
        var descriptor = FetchDescriptor<PlaceModel>(
            predicate: #Predicate { $0.id == dto.placeId }
        )
        descriptor.fetchLimit = 1

        if let existingPlace = try context.fetch(descriptor).first {
            return existingPlace
        }

        let createdPlace = PlaceModel(
            id: dto.placeId,
            name: dto.name,
            latitude: dto.latitude,
            longitude: dto.longitude,
            address: dto.address
        )
        context.insert(createdPlace)
        return createdPlace
    }
}
