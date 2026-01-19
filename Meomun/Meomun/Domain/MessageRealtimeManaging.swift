//
//  MessageRealtimeManaging.swift
//  Meomun
//
//  Created by 지연 on 1/16/26.
//

protocol MessageRealtimeManaging: Sendable {
    func subscribeNearby(topic: String) -> AsyncStream<MessageRealtimeEvent>
    func unsubscribeNearby()
}
