//
//  DeleteMessageUseCase.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

protocol DeleteMessageUseCase {
    func execute(for messageIDs: Set<MessageID>) async throws
}

final class DeleteMessageUseCaseImpl: DeleteMessageUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(for messageIDs: Set<MessageID>) async throws {
        try await messageRepository.deleteMessages(messageIDs: messageIDs)
    }
}
