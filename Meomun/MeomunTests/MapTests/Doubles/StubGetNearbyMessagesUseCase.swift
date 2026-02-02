//
//  StubGetNearbyMessagesUseCase.swift
//  MeomunTests
//
//  Created by MinwooJe on 1/20/26.
//

import Foundation
@testable import Meomun

final class StubGetNearbyMessagesUseCase: GetNearbyMessagesUseCase {

    /// 반환할 메시지 배열 (성공 케이스)
    private(set) var stubbedMessages: [Message] = []

    /// throw할 에러 (실패 케이스, nil이면 성공)
    private(set) var stubbedError: Error?

    /// 응답 지연 시간 (debounce 테스트용)
    private(set) var stubbedDelay: UInt64

    init(
        stubbedMessages: [Message],
        stubbedError: Error? = nil,
        stubbedDelay: UInt64 = 0
    ) {
        self.stubbedMessages = stubbedMessages
        self.stubbedError = stubbedError
        self.stubbedDelay = stubbedDelay
    }

    // MARK: - GetNearbyMessagesUseCase

    func execute(at location: Meomun.Coordinate, bounds: Meomun.BoundingBox, limit: Int?) async throws -> [Meomun.Message] {
        if stubbedDelay > 0 {
            try await Task.sleep(nanoseconds: stubbedDelay)
        }

        if let error = stubbedError {
            throw error
        }

        return stubbedMessages
    }
}
