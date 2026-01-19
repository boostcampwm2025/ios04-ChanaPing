//
//  FetchPlaceMessagesUseCase.swift
//  Meomun
//
//  Created by hoon on 1/15/26.
//

import Foundation

protocol FetchPlaceMessagesUseCase: Sendable {
    func execute(
        placeID: PlaceID,
        limit: Int?
    ) async throws -> [Message]
}

extension FetchPlaceMessagesUseCase {
    func execute(
        placeID: PlaceID
    ) async throws -> [Message] {
        try await execute(placeID: placeID, limit: nil)
    }
}

struct FetchPlaceMessagesUseCaseImpl: FetchPlaceMessagesUseCase, Sendable {

    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        let messages = try await messageRepository.getPlaceMessages(
            placeID: placeID,
            limit: limit
        )

        return messages.sorted { $0.createdAt > $1.createdAt }
    }
}
