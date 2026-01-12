//
//  MessageRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct CreateMessageRequest: Sendable {
    let text: String
    let location: Location
    let placeID: PlaceID?
}

protocol MessageRepository: Sendable {
    func createMessage(_ request: CreateMessageRequest) async throws
    func deleteMessage(messageID: MessageID) async throws

    func reportMessage(messageID: MessageID) async throws -> MessageID

    func saveMessage(messageID: MessageID) async throws
    func deleteSavedMessages(messageIDs: [MessageID]) async throws

    func getNearbyMessages(location: Location, limit: Int?) async throws -> [Message]
    func getPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message]
}
