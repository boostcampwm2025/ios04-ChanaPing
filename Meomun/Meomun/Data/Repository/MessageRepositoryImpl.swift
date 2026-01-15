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
        AppLog.debug(
            "getPlaceMessages RPC request: placeID=\(placeID.value), limit=\(limit.map(String.init) ?? "nil")",
            category: .repository
        )

        do {
            var params: [String: AnyJSON] = ["p_place_id": .string(placeID.value)]

            if let limit {
                params["p_limit"] = .double(Double(limit))
            }

            let response: [MessageDTO] = try await supabase
                .rpc("get_place_messages", params: params)
                .execute()
                .value

            let messages = response.map { $0.toDomain() }

            AppLog.debug(
                "getPlaceMessages RPC success: rows=\(response.count), messages=\(messages.count)",
                category: .repository
            )

            return messages
        } catch {
            AppLog.error(
                "getPlaceMessages RPC failed: placeID=\(placeID.value)",
                category: .repository,
                error: error
            )

            throw error
        }
    }
}
