//
//  SpyGetNearbyMessagesUseCase.swift
//  MeomunTests
//
//  Created by MinwooJe on 1/20/26.
//

import Foundation
@testable import Meomun

final class SpyGetNearbyMessagesUseCase: GetNearbyMessagesUseCase {

    private(set) var calledLocations: [Coordinate] = []

    var executeCallCount: Int { calledLocations.count }

    var lastCalledLocation: Coordinate? { calledLocations.last }

    private(set) var stubbedMessages: [Message] = []

    init(stubbedMessages: [Message] = []) {
        self.stubbedMessages = stubbedMessages
    }

    func execute(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [Message] {
        calledLocations.append(location)
        return stubbedMessages
    }
}
