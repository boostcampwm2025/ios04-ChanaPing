//
//  MessageRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

final class MessageRepositoryImpl: MessageRepository {
    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient = SupabaseService.shared.client) {
        self.supabaseClient = supabaseClient
    }

    func createMessage(_ request: CreateMessageRequestDTO) async throws {
        let session = try await supabaseClient.auth.session

        let authHeader = "Bearer \(session.accessToken)"

        do {
            _ = try await supabaseClient.functions.invoke(
                "messages",
                options: FunctionInvokeOptions(
                    method: .post,
                    headers: ["Authorization": authHeader],
                    body: request
                ),
                decode: { _, response in
                    if (200...299).contains(response.statusCode) { return () }
                    throw NSError(domain: "EdgeFunction", code: response.statusCode)
                }
            )
        } catch FunctionsError.httpError(let code, let data) {
            let raw = String(data: data, encoding: .utf8) ?? ""

            if code == 401 {
                throw CreateMessageError.unauthorized
            }

            if code == 422 {
                if let dto = try? JSONDecoder().decode(CreateMessageErrorResponseDTO.self, from: data) {
                    throw CreateMessageError.blocked(details: dto)
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
