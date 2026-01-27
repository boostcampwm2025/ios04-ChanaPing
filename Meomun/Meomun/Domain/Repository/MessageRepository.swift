//
//  MessageRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

protocol MessageRepository: Sendable {
    func createMessage(_ request: CreateMessageRequest) async throws
    func updateMessage(_ request: Message) async throws
    func deleteMessages(messageIDs: [MessageID]) async throws

    func fetchNearbyMessages(location: Coordinate, limit: Int?) async throws -> [Message]
    func fetchPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message]
    func fetchRecentMessages(page: Int, pageSize: Int) async throws -> [Message]
}
