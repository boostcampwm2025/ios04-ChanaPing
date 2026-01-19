//
//  MessageRealtimeManager.swift
//  Meomun
//
//  Created by 지연 on 1/16/26.
//

import Supabase
import Foundation

final class MessageRealtimeManager: MessageRealtimeManaging {
    private let supabase: SupabaseClient

    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?

    init(supabase: SupabaseClient = SupabaseService.shared.client) {
        self.supabase = supabase
    }

    func subscribeNearby(topic: String = "messages:nearby") -> AsyncStream<MessageRealtimeEvent> {
        AsyncStream { continuation in
            stopListening()

            let channel = supabase.realtimeV2.channel("messages-nearby")
            self.channel = channel

            listenTask = Task { [weak self] in
                guard let self else { return }
                defer { continuation.finish() }

                await channel.subscribe()
                AppLog.debug("subscribed to \(topic)", category: .realtime)

                let stream = channel.broadcastStream(event: topic)

                for await message in stream {
                    if Task.isCancelled { break }

                    if let event = self.parseBroadcast(message) {
                        continuation.yield(event)
                    } else {
                        AppLog.error("failed to parse message: \(message)", category: .realtime)
                    }
                }
            }
            continuation.onTermination = { [weak self] _ in
                self?.stopListening()
            }
        }
    }

    func unsubscribeNearby() {
        stopListening()
    }
}

private extension MessageRealtimeManager {
    func stopListening() {
        listenTask?.cancel()
        listenTask = nil

        guard let channel else { return }

        Task { [weak self] in
            await channel.unsubscribe()
            self?.channel = nil
            AppLog.debug("unsubscribed from messages-nearby", category: .realtime)
        }
    }

    func parseBroadcast(_ message: JSONObject) -> MessageRealtimeEvent? {
            let root = extractPayloadObject(from: message)

            guard let type = root["type"]?.stringValue else { return nil }

            switch type {
            case "created":
                do {
                    let data = try JSONSerialization.data(withJSONObject: root.toAnyObject(), options: [])
                    let dto = try JSONDecoders.iso8601.decode(RealtimeCreatedMessageDTO.self, from: data)
                    return .created(dto.toDomain())
                } catch {
                    AppLog.error("created decode failed:", category: .realtime, error: error)
                    return nil
                }

            case "deleted":
                return parseIdEvent(root, as: .deleted)

            case "expired":
                return parseIdEvent(root, as: .expired)

            case "stale":
                return parseIdEvent(root, as: .becameStale)

            default:
                return nil
            }
        }

        func extractPayloadObject(from message: JSONObject) -> JSONObject {
            // 1) payload 키로 감싸진 경우
            if let payload = message["payload"]?.objectValue {
                return payload
            }
            // 2) 바로 내려오는 경우
            return message
        }

        enum IdEventKind {
            case deleted, expired, becameStale
        }

        func parseIdEvent(_ root: JSONObject, as kind: IdEventKind) -> MessageRealtimeEvent? {
            guard
                let idString = root["id"]?.stringValue,
                let uuid = UUID(uuidString: idString)
            else { return nil }

            let id = MessageID(value: uuid)

            switch kind {
            case .deleted:
                return .deleted(id: id)

            case .expired:
                return .expired(id: id)

            case .becameStale:
                return .becameStale(id: id)
            }
        }
}
