//
//  MessagesByCoordinate.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

import Foundation

struct MessagesByCoordinate {
    private(set) var groups: [Location: SameCoordinateMessageGroup]

    init(groups: [Location: SameCoordinateMessageGroup]) {
        self.groups = groups
    }

    mutating func groupAll(for messages: [Message]) {
        var newGroups: [Location: SameCoordinateMessageGroup] = [:]

        for message in messages {
            let coordinate = message.location
            var group = newGroups[coordinate] ?? SameCoordinateMessageGroup(coordinate: coordinate)
            group.append(message)
            newGroups[coordinate] = group
        }

        self.groups = newGroups
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
        var group = groups[coordinate] ?? SameCoordinateMessageGroup(coordinate: coordinate)
        group.append(message)
        groups[coordinate] = group
    }

    private mutating func remove(_ message: Message) {
        let coordinate = message.location
        guard var group = groups[coordinate] else { return }

        group.remove(message)

        if group.isEmpty {
            groups.removeValue(forKey: coordinate)
        } else {
            groups[coordinate] = group
        }
    }
}
