//
//  MessageRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

// 임시 값
struct CreateMessageRequest: Sendable {
    let text: String
    let placeID: PlaceID?
    let coordinate: Coordinate?
}

protocol MessageRepository: Sendable {
    func createMessage(_ request: CreateMessageRequest) async throws -> Message
    func deleteMessage(messageID: MessageID) async throws

    func reportMessage(messageID: MessageID, description: String?) async throws

    func saveMessage(messageID: MessageID) async throws
    func deleteSavedMessage(messageID: MessageID) async throws
    func deleteSavedMessages(messageIDs: [MessageID]) async throws

    func getNearbyMessages(center: Coordinate, radiusMeters: Double, limit: Int?) async throws -> [Message]
    func getPlaceMessages(placeID: PlaceID, limit: Int?, before: Date?) async throws -> [Message]
}
