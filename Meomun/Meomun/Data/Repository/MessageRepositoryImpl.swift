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
        var params: [String: AnyJSON] = [
            "p_lat": .double(location.latitude),
            "p_lon": .double(location.longitude)
        ]

        if let limit {
            params["p_limit"] = .double(Double(limit))
        }

        let response = try await supabase
            .rpc("get_nearby_messages", params: params)
            .execute()

        let dtos = try JSONDecoders.iso8601.decode([NearbyMessageResponseDTO].self, from: response.data)

        return dtos.map { $0.toDomain() }
    }

    func getPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        return []
    }
}
