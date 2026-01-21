//
//  MessageEvent.swift
//  Meomun
//
//  Created by MinwooJe on 1/13/26.
//

struct MessageEvent {
    let type: MessageEventType
    let message: Message
}

enum MessageEventType {
    case insert
    case delete
}
