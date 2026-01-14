//
//  MessagesByCoordinate.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import Foundation

final class MessagesByCoordinate {
    private(set) var messagesByCoordinate: [Location: MessageCoordinateGroup]

    init(groupedMessages: [Location: MessageCoordinateGroup]) {
        self.messagesByCoordinate = groupedMessages
    }

    func groupAll(for messages: [Message]) {
        var newGroups: [Location: MessageCoordinateGroup] = [:]

        for message in messages {
            let location = message.location
            var group = newGroups[location] ?? MessageCoordinateGroup(coordinate: location)
            group.add(message)
            newGroups[location] = group
        }

        self.messagesByCoordinate = newGroups
    }

    func update(_ messageEvent: MessageEvent) {
        let message = messageEvent.message

        switch messageEvent.event {
        case .insert:
            append(message)
        case .delete:
            remove(message)
        }
    }

    private func append(_ message: Message) {
        let location = message.location
        var group = messagesByCoordinate[location] ?? MessageCoordinateGroup(coordinate: location)
        group.add(message)
        messagesByCoordinate[location] = group
    }

    private func remove(_ message: Message) {
        let location = message.location
        guard var group = messagesByCoordinate[location] else { return }

        group.remove(message)

        if group.isEmpty {
            messagesByCoordinate.removeValue(forKey: location)
        } else {
            messagesByCoordinate[location] = group
        }
    }
}
