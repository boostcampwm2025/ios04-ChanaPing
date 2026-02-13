//
//  SpaceMessageBubbleSynchronizer.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit
import Foundation
import UIKit

@MainActor
final class SpaceMessageBubbleSynchronizer {
    private var bubbleRootByID: [MessageID: Entity] = [:]
    private var placementByID: [MessageID: BubblePlacementRecord] = [:]
    private let factory: SpaceMessageBubbleFactory

    private let materialConfigurator: SpaceMaterialConfigurator = .init()
    private var selectedID: MessageID?

    init(factory: SpaceMessageBubbleFactory = .init()) {
        self.factory = factory
    }

    var allBubbleRoots: [Entity] { Array(bubbleRootByID.values) }

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

    func applySelection(selectedID newID: MessageID?) {
        if let oldID = selectedID,
           let oldRoot = bubbleRootByID[oldID] {
            restoreBaseGlow(root: oldRoot, messageID: oldID)
        }

        selectedID = newID

        guard let newID,
              let newRoot = bubbleRootByID[newID]
        else { return }

        setHighlightGlow(root: newRoot, messageID: newID)
    }

    private func addMessage(
        message: Message,
        root: Entity,
        templateEntity: Entity
    ) {
        let bubblePlacer = BubblePlacer()

        let multiplier = factory.bubbleUniformMultiplier(message: message, templateEntity: templateEntity)
        let finalScale = SpaceBubbleLayoutPolicy.baseBubbleScale * multiplier

        let collisionBoxSize = SIMD3<Float>(
            repeating: 0.3 * finalScale / SpaceBubbleLayoutPolicy.baseBubbleScale
        )
        let radius = BubbleCollisionRadiusCalculator.radius(fromBoxSize: collisionBoxSize)

        let existing = Array(placementByID.values)

        let position = bubblePlacer.randomNonOverlappingPositionInsideHemisphere(
            radiusRange: SpaceBubblePositionPolicy.minRadius...SpaceBubblePositionPolicy.maxRadius,
            yRange: SpaceBubblePositionPolicy.minYPosition...SpaceBubblePositionPolicy.maxYPosition,
            minimumDistanceFromCenter: SpaceBubblePositionPolicy.minDistanceFromCenter,
            minimumDistanceFromViewAxis: SpaceBubblePositionPolicy.minDistanceFromViewAxis,
            maxAttempts: SpaceBubblePositionPolicy.maxAttempts,
            requiredRadius: radius,
            existing: existing,
            spacing: SpaceBubblePositionPolicy.minBubbleSpacing
        )

        let bubbleRoot = factory.makeBubbleRoot(
            message: message,
            templateEntity: templateEntity,
            position: position
        )

        root.addChild(bubbleRoot)
        attachFloatingIfNeeded(to: bubbleRoot)

        bubbleRootByID[message.id] = bubbleRoot
        placementByID[message.id] = BubblePlacementRecord(
            messageID: message.id,
            position: position,
            radius: radius
        )
    }

    private func removeMessage(id: MessageID) {
        guard let entity = bubbleRootByID[id] else { return }
        entity.removeFromParent()
        bubbleRootByID[id] = nil
        placementByID[id] = nil
    }
}

private extension SpaceMessageBubbleSynchronizer {
    func restoreBaseGlow(root: Entity, messageID: MessageID) {
        guard let model = root.findEntity(named: "MessageModel-\(messageID.value.uuidString)") else { return }

        let defaultGlowColor = UIColor(red: 0.278, green: 0.600, blue: 0.741, alpha: 1.0)
        materialConfigurator
            .setMessageGlowColor(messageEntity: model, color: defaultGlowColor)
    }

    func setHighlightGlow(root: Entity, messageID: MessageID) {
        guard let model = root.findEntity(named: "MessageModel-\(messageID.value.uuidString)") else { return }

        let highlightGlowColor = UIColor.systemRed.withAlphaComponent(0.8)
        materialConfigurator.setMessageGlowColor(messageEntity: model, color: highlightGlowColor)
    }

    func attachFloatingIfNeeded(to entity: Entity) {
        if entity.components[FloatingComponent.self] != nil { return }

        let baseY = entity.position.y
        entity.components.set(
            FloatingComponent(
                baseY: baseY,
                amplitude: .random(in: 0.02...0.04),
                frequency: .random(in: 0.8...1.0),
                phase: .random(in: 0...(2 * .pi)),
                yawAmplitude: .random(in: 0.03...0.08)
            )
        )
    }
}
