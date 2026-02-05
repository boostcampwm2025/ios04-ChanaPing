//
//  HasAnyMessageUseCase.swift
//  Meomun
//
//  Created by 지연 on 2/5/26.
//

protocol HasAnyMessageUseCase {
    func execute() async throws -> Bool
}

final class HasAnyMessageUseCaseImpl: HasAnyMessageUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute() async throws -> Bool {
        try await messageRepository.hasAny()
    }
}
