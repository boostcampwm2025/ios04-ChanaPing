//
//  ResetMessagesUseCase.swift
//  Meomun
//
//  Created by Hayeon Park on 2/2/26.
//

protocol ResetMessagesUseCase {
    func execute() async throws
}

final class ResetMessagesUseCaseImpl: ResetMessagesUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute() async throws {
        try await messageRepository.resetMessages()
    }
}
