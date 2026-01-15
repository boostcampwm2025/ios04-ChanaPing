//
//  MessageRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

struct CreateMessageRequest: Sendable {
    let text: String
    let placeID: PlaceID?
    let coordinate: Coordinate?
}

final class MessageRepositoryImpl: MessageRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseService.shared.client) {
        self.supabase = supabase
    }

    func createMessage(_ request: CreateMessageRequestDTO) async throws {
        do {
            _ = try await supabase.functions.invoke(
                "messages",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: request
                ),
                decode: { _, response in
                    if (200...299).contains(response.statusCode) { return () }
                }
            )

            return
        } catch FunctionsError.httpError(let code, let data) {
            let raw = String(data: data, encoding: .utf8) ?? ""

            if code == 401 {
                throw CreateMessageError.unauthorized
            }

            if code == 422 {
                if let dto = try? JSONDecoder().decode(CreateMessageErrorResponseDTO.self, from: data) {
                    // code: CONTENT_BLOCKED / CONTENT_UNKNOWN
                    switch dto.code {
                    case "CONTENT_BLOCKED":
                        throw CreateMessageError.blocked(details: dto)
                    case "CONTENT_UNKNOWN":
                        throw CreateMessageError.unknown(details: dto)
                    default:
                        throw CreateMessageError.http(code: code, rawBody: raw)
                    }
                } else {
                    throw CreateMessageError.http(code: code, rawBody: raw)
                }
            }

            throw CreateMessageError.http(code: code, rawBody: raw)
        } catch {
            throw error
        }
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
