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

    func createMessage(_ request: CreateMessageRequest) async throws {
        let session = try await supabaseClient.auth.session

        let authHeader = "Bearer \(session.accessToken)"

        let placeDTO: PlaceDTO? = request.place.map { place in
            PlaceDTO(
                placeId: place.id.value,
                name: place.name,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                address: place.address.isEmpty ? nil : place.address
            )
        }

        let dto = CreateMessageRequestDTO(
            content: request.content,
            latitude: request.coordinate.latitude,
            longitude: request.coordinate.longitude,
            place: placeDTO
        )

        do {
            _ = try await supabaseClient.functions.invoke(
                "messages",
                options: FunctionInvokeOptions(
                    method: .post,
                    headers: ["Authorization": authHeader],
                    body: dto
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
        var params: [String: AnyJSON] = [
            "p_lat": .double(location.latitude),
            "p_lon": .double(location.longitude)
        ]

        if let limit {
            params["p_limit"] = .double(Double(limit))
        }

        let response = try await supabaseClient
            .rpc("get_nearby_messages", params: params)
            .execute()

        let dtos = try JSONDecoders.iso8601.decode([NearbyMessageResponseDTO].self, from: response.data)

        return dtos.map { $0.toDomain() }
    }

    func getPlaceMessages(placeID: PlaceID, limit: Int?) async throws -> [Message] {
        AppLog.debug(
            "getPlaceMessages RPC request: placeID=\(placeID.value), limit=\(limit.map(String.init) ?? "nil")",
            category: .repository
        )

        do {
            var params: [String: AnyJSON] = ["p_place_id": .string("bcdbf174-ee39-44dc-a77b-cb2034ff8d0d")]

            if let limit {
                params["p_limit"] = .double(Double(limit))
            }

            let response: [PlaceMessageResponseDTO] = try await supabaseClient
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
