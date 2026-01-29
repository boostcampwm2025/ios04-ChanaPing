//
//  SpaceMessageBubbleSynchronizer.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit

@MainActor
final class SpaceMessageBubbleSynchronizer {
    private var bubbleRootByID: [MessageID: Entity] = [:]
    private let factory: SpaceMessageBubbleFactory

    init(factory: SpaceMessageBubbleFactory = .init()) {
        self.factory = factory
    }

    func sync(to root: Entity, messages: [Message], templateEntity: Entity) {
        let incomingMessageIDs = Set(messages.map(\.id))
        let existingMessageIDs = Set(bubbleRootByID.keys)

        let idSetToRemove = existingMessageIDs.subtracting(incomingMessageIDs)
        let idSetToAdd = incomingMessageIDs.subtracting(existingMessageIDs)

        // 1. remove
        for messageID in idSetToRemove {
            removeMessage(id: messageID)
        }

        // 2.add
        for messageID in idSetToAdd {
            guard let message = messages.first(where: { $0.id == messageID }) else { continue }

            addMessage(message: message, root: root, templateEntity: templateEntity)
        }
    }

    private func addMessage(
        message: Message,
        root: Entity,
        templateEntity: Entity
    ) {
        let bubbleRoot = factory.makeBubbleRoot(
            message: message,
            templateEntity: templateEntity
        )
        root.addChild(bubbleRoot)
        bubbleRootByID[message.id] = bubbleRoot
    }

    private func removeMessage(id: MessageID) {
        guard let entity = bubbleRootByID[id] else { return }
        entity.removeFromParent()
        bubbleRootByID[id] = nil
    }
}
