//
//  MessageInMemoryStorage.swift
//  Meomun
//
//  Created by MinwooJe on 1/22/26.
//

import Foundation

actor MessageInMemoryStorage: MessageStorage {
    private var storage: [MessageResponseDTO] = []

    static let shared = MessageInMemoryStorage()

    private init() { }

    func fetchNearby(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [MessageResponseDTO] {
        // 인메모리 임시 구현이므로 반경 필터링 생략
        storage
    }

    func fetchByPlace(at placeID: PlaceID, limit: Int?) async throws -> [MessageResponseDTO] {
        storage
            .lazy
            .filter { $0.place?.placeId == placeID.value }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit ?? Int.max)
            .map { $0 }
    }

    func fetchRecent(page: Int, pageSize: Int) async throws -> [MessageResponseDTO] {
        // 1. 최신순 정렬
        let sorted = storage.sorted { $0.createdAt > $1.createdAt }

        // 2. startIndex 계산
        let startIndex = page * pageSize

        guard startIndex < sorted.count else {
            return []
        }

        // 4. 페이지 슬라이싱
        let endIndex = min(startIndex + pageSize, sorted.count)
        let pageData = Array(sorted[startIndex..<endIndex])

        return pageData
    }

    func hasAny() async throws -> Bool {
        !storage.isEmpty
    }

    func create(for message: CreateMessageRequestDTO) async throws {
        let newMessage = MessageResponseDTO(
            id: .init(),
            createdAt: .init(),
            content: message.content,
            latitude: message.latitude,
            longitude: message.longitude,
            address: message.address,
            place: message.place
        )

        storage.append(newMessage)
    }

    func update(for message: UpdateMessageRequestDTO) async throws {
        _ = MessageResponseDTO(
            id: message.id,
            createdAt: message.createdAt,
            content: message.content,
            latitude: message.latitude,
            longitude: message.longitude,
            address: message.address,
            place: message.place
        )
    }

    func delete(messageIDs: Set<MessageID>) async throws {
        storage.removeAll { message in
            messageIDs.contains(MessageID(value: message.id))
        }
    }

    func reset() async throws {
        storage.removeAll(keepingCapacity: false)
    }
}
