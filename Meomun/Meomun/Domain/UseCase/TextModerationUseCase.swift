//
//  TextModerationUseCase.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation

protocol TextModerationUseCase {
    func execute(text: String) async throws -> TextModerationResponse
}

final class TextModerationUseCaseImpl: TextModerationUseCase {
    private let messageRepository: MessageRepository

    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
    }

    func execute(text: String) async throws -> TextModerationResponse {
        let response = try await messageRepository.moderateMessage(text: text)
        return response
    }
}
