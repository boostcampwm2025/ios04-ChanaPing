//
//  MessageSwiftDataStorage.swift
//  Meomun
//
//  Created by Hayeon Park on 1/26/26.
//

import SwiftData
import Foundation

actor MessageSwiftDataStorage: MessageStorage {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    private func makeContext() -> ModelContext {
        return ModelContext(container)
    }

    func fetchNearby(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [MessageResponseDTO] {
        let context = makeContext()

        let minLatitude = bounds.minLatitude
        let maxLatitude = bounds.maxLatitude
        let minLongitude = bounds.minLongitude
        let maxLongitude = bounds.maxLongitude

        // 1차: BoundingBox 범위로 필터링
        let descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { message in
                message.latitude >= minLatitude &&
                message.latitude <= maxLatitude &&
                message.longitude >= minLongitude &&
                message.longitude <= maxLongitude
            }
        )
        let filteredData = try context.fetch(descriptor)

        // 2차: 거리 계산 정렬
        let sortedData = filteredData
            .map { item -> (MessageModel, Double) in
                let other = Coordinate(latitude: item.latitude, longitude: item.longitude)
                return (item, location.distance(to: other))
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }

        let results = limit.map { Array(sortedData.prefix($0)) } ?? sortedData
        return results.map { $0.toDTO() }
    }

    func fetchByPlace(at placeID: PlaceID, limit: Int?) async throws -> [MessageResponseDTO] {
        let context = makeContext()

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
        let context = makeContext()

        var descriptor = FetchDescriptor<MessageModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(0, page) * pageSize

        let results = try context.fetch(descriptor)
        return results.map { $0.toDTO() }
    }

    func create(for message: CreateMessageRequestDTO) async throws {
        let context = makeContext()

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

    func delete(messageIDs: Set<MessageID>) async throws {
        let context = makeContext()

        // Message.id: MessageID, MessageModel.id: UUID 이므로 타입을 맞추기 위해 map으로 변환
        let messageIdValues: Set<UUID> = Set(messageIDs.map { $0.value })

        let descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { message in
                messageIdValues.contains(message.id)
            }
        )

        let targets = try context.fetch(descriptor)

        for target in targets {
            context.delete(target)
        }

        if !targets.isEmpty {
            try context.save()

        } else {
            AppLog.warn("삭제할 대상 데이터가 없어요. MessageID : \(messageIDs)", category: .storage)
        }
    }

    func update(for message: UpdateMessageRequestDTO) async throws {
        let context = makeContext()

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

    func reset() async throws {
        let context = makeContext()

        for model in AppDataConfig.modelList {
            try context.delete(model: model)
        }

        try context.save()
    }
}

private extension MessageSwiftDataStorage {
    func fetchOrCreatePlace(dto: PlaceDTO, context: ModelContext) throws -> PlaceModel {
        let placeId = dto.placeId

        var descriptor = FetchDescriptor<PlaceModel>(
            predicate: #Predicate { $0.id == placeId }
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
