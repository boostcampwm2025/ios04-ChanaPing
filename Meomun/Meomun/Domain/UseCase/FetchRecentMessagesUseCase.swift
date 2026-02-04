//
//  FetchRecentMessagesUseCase.swift
//  Meomun
//
//  Created by MinwooJe on 1/23/26.
//

protocol FetchRecentMessagesUseCase {
    func execute(page: Int, pageSize: Int) async throws -> [Message]
}

final class FetchRecentMessagesUseCaseImpl: FetchRecentMessagesUseCase {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }

    func execute(page: Int, pageSize: Int) async throws -> [Message] {
        try await repository.fetchRecentMessages(page: page, pageSize: pageSize)
    }
}
