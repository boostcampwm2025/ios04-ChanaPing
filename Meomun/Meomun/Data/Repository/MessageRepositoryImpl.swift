//
//  MessageRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

final class MessageRepositoryImpl: MessageRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseService.shared.client) {
        self.supabase = supabase
    }

    func moderateMessage(text: String) async throws -> TextModerationResponse {
        let response: TextModerationResponse = try await supabase.functions
            .invoke(
                "text-moderation",
                options: FunctionInvokeOptions(
                    body: ["text": text]
                )
            )

        return response
    }

    func createMessage(_ request: CreateMessageRequest) async throws {
        return
    }

    func deleteMessage(messageID: MessageID) async throws {
        return
    }

    func reportMessage(messageID: MessageID) async throws -> MessageID {
        return MessageID(value: UUID())
    }

    func saveMessage(messageID: MessageID) async throws {
        return
    }

    func deleteSavedMessages(messageIDs: [MessageID]) async throws {
        return
    }

    func getNearbyMessages(location: Coordinate, limit: Int?) async throws -> [Message] {
        return []
    }

    func getPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        return []
    }
}
