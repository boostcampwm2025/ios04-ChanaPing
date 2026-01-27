//
//  GetNearbyMessagesUseCase.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

protocol GetNearbyMessagesUseCase {
    func execute(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [Message]
}

final class GetNearbyMessagesUseCaseImpl: GetNearbyMessagesUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [Message] {
        try await messageRepository.fetchNearbyMessages(at: location, bounds: bounds, limit: limit)
    }
}
