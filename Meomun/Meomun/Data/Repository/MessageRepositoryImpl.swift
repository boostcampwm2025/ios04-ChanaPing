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
        var query = supabase
            .from("messages")
            .select(
                """
                id,
                author_id,
                created_at,
                content,
                latitude,
                longitude,
                expires_at,
                deleted_at,
                place_id,
                place:place_id(
                    place_id,
                    name,
                    latitude,
                    longitude,
                    created_at
                )
                """
            )
            .eq("place_id", value: placeID.value)
            .order("created_at", ascending: false)

        if let limit {
            query = query.limit(limit)
        }

        AppLog.debug(
            "getPlaceMessages request: placeID=\(placeID.value)",
            category: .repository
        )

        do {
            let rows: [MessageDTO] = try await query.execute().value
            let messages = toDomainMessages(rows)

            AppLog.debug(
                "getPlaceMessages success: rows=\(rows.count), messages=\(messages.count)",
                category: .repository
            )

            return messages
        } catch {
            AppLog.error(
                "getPlaceMessages failed: placeID=\(placeID.value)",
                category: .repository,
                error: error
            )

            throw error
        }
    }
}

// MARK: - Mapping

extension MessageRepositoryImpl {
    private func toDomainMessages(_ rows: [MessageDTO]) -> [Message] {
        let now = Date()

        return rows
            .filter { $0.deletedAt == nil && $0.expiresAt > now }
            .map { row in
                let coordinate = Coordinate(latitude: row.latitude, longitude: row.longitude)

                let placeTag: Place? = row.place.map { place in
                    Place(
                        id: PlaceID(value: place.placeID),
                        name: place.name,
                        coordinate: Coordinate(latitude: place.latitude, longitude: place.longitude),
                        address: ""
                    )
                }

                return Message(
                    id: MessageID(value: row.id),
                    authorID: UserID(value: row.authorID),
                    createdAt: row.createdAt,
                    content: row.content,
                    coordinate: coordinate,
                    placeTag: placeTag
                )
            }
    }
}
