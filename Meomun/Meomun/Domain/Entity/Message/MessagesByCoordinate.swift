//
//  MessagesByCoordinate.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import Foundation

struct MessagesByCoordinate {
    private(set) var messagesByCoordinate: [Location: MessageCoordinateGroup]

    init(groupedMessages: [Location: MessageCoordinateGroup]) {
        self.messagesByCoordinate = groupedMessages
    }

    mutating func groupAll(for messages: [Message]) {
        var newGroups: [Location: MessageCoordinateGroup] = [:]

        for message in messages {
            let coordinate = message.location
            var group = newGroups[coordinate] ?? MessageCoordinateGroup(coordinate: coordinate)
            group.add(message)
            newGroups[coordinate] = group
        }

        self.messagesByCoordinate = newGroups
    }

    mutating func update(_ messageEvent: MessageEvent) {
        let message = messageEvent.message

        switch messageEvent.event {
        case .insert:
            append(message)
        case .delete:
            remove(message)
        }
    }

    private mutating func append(_ message: Message) {
        let coordinate = message.location
        var group = messagesByCoordinate[coordinate] ?? MessageCoordinateGroup(coordinate: coordinate)
        group.add(message)
        messagesByCoordinate[coordinate] = group
    }

    private mutating func remove(_ message: Message) {
        let coordinate = message.location
        guard var group = messagesByCoordinate[coordinate] else { return }

        group.remove(message)

        if group.isEmpty {
            messagesByCoordinate.removeValue(forKey: coordinate)
        } else {
            messagesByCoordinate[coordinate] = group
        }
    }
}
