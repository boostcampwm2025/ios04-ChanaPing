//
//  DeleteMessagesUseCase.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

protocol DeleteMessagesUseCase {
    func execute(for messageIDs: Set<MessageID>) async throws
}

final class DeleteMessagesUseCaseImpl: DeleteMessagesUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(for messageIDs: Set<MessageID>) async throws {
        try await messageRepository.deleteMessages(messageIDs: messageIDs)
    }
}
