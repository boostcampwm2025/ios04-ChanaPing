//
//  CreateMessageUseCase.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation

protocol CreateMessageUseCase {
    func execute(_ request: CreateMessageRequestDTO) async throws
}

final class CreateMessageUseCaseImpl: CreateMessageUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(_ request: CreateMessageRequestDTO) async throws {
        try await messageRepository.createMessage(request)
    }
}
