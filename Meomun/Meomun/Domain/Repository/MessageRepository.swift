//
//  MessageRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

protocol MessageRepository: Sendable {
    func createMessage(_ request: CreateMessageRequest) async throws
    func deleteMessage(messageID: MessageID) async throws

    func getNearbyMessages(location: Coordinate, limit: Int?) async throws -> [Message]
    func getPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message]
}
