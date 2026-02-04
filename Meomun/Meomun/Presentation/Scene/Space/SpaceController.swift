//
//  SpaceController.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit
import SwiftUI

@MainActor
final class SpaceController {
    private var domeEnvironment: DomeEnvironment?
    private var rotationCamera: RotationCamera

    private var spaceRootEntity: Entity?
    private var messageBubbleTemplateEntity: Entity?
    private var domeEntity: Entity?

    private var syncTask: Task<Void, Never>?
    private var pendingMessages: [Message] = []

    private let bubbleSynchronizer: SpaceMessageBubbleSynchronizer
    private let materialConfigurator: SpaceMaterialConfigurator

    private var configureTask: Task<Void, Never>?
    private var isConfiguring: Bool = false
    private var didFinishConfigure: Bool = false
    private var readyHandlers: [() -> Void] = []

    init(
        rotationCamera: RotationCamera = .init(
            position: .init(x: 0, y: 0.7, z: 0),
            rotateSensitivity: 0.003
        )
    ) {
        self.rotationCamera = rotationCamera
        self.bubbleSynchronizer = SpaceMessageBubbleSynchronizer()
        self.materialConfigurator = SpaceMaterialConfigurator()
    }

    // MARK: - Space Setup
    func configureSpace(content: RealityViewCameraContent, onReady: (() -> Void)? = nil) {
        if let onReady { readyHandlers.append(onReady) }

        if didFinishConfigure {
            flushReadyHandlers()
            return
        }

        if isConfiguring { return }

        isConfiguring = true

        configureTask?.cancel()
        configureTask = Task { [weak self] in
            guard let self else { return }

            do {
                defer { isConfiguring = false }

                // Camera 추가
                rotationCamera.addToScene(content)

                // SpaceRoot 생성: 돔/버블 오브젝트를 한 곳에 묶는 컨테이너
                let root = Entity()
                root.name = "SpaceRoot"
                content.add(root)

                spaceRootEntity = root

                // Dome 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                domeEntity.name = "Dome"
                self.domeEntity = domeEntity

                // 머테리얼 세팅
                if let domeEnvironment = domeEnvironment {
                    materialConfigurator.configureDome(
                        domeEntity: domeEntity,
                        dayPart: domeEnvironment.dayPart
                    )

                    materialConfigurator.configureGround(
                        domeEntity: domeEntity,
                        dayPart: domeEnvironment.dayPart
                    )
                }

                root.addChild(domeEntity)

                // Message template 로드
                let messageEntity = try await Entity(named: "Message.usdz")
                messageEntity.name = "MessageBubble"

                materialConfigurator.configureMessage(messageEntity: messageEntity)

                // 터치 이벤트 수신을 위해 InputTargetComponent 추가
                messageEntity.components.set(InputTargetComponent())

                messageBubbleTemplateEntity = messageEntity

                didFinishConfigure = true
                flushReadyHandlers()

                trySyncIfPossible()
            } catch {
                AppLog.error(
                    "Failed to configure Space scene",
                    category: .space,
                    error: error
                )
            }
        }
    }

    private func flushReadyHandlers() {
        let handlers = readyHandlers
        readyHandlers.removeAll()
        handlers.forEach { $0() }
    }
}

// MARK: - Message Sync

extension SpaceController {
    func sync(messages: [Message]) {
        pendingMessages = messages
        trySyncIfPossible()
    }

    func update(domeEnvironment: DomeEnvironment) {
        self.domeEnvironment = domeEnvironment

        guard let domeEntity else { return }

        // 머테리얼 업데이트
        materialConfigurator.configureDome(
            domeEntity: domeEntity,
            dayPart: domeEnvironment.dayPart
        )

        materialConfigurator.configureGround(
            domeEntity: domeEntity,
            dayPart: domeEnvironment.dayPart
        )
    }

    private func trySyncIfPossible() {
        guard let root = spaceRootEntity else { return }
        guard let template = messageBubbleTemplateEntity else { return }

        let snapshot = pendingMessages

        syncTask?.cancel()
        syncTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            bubbleSynchronizer.sync(
                to: root,
                messages: snapshot,
                templateEntity: template
            )

            bringOneBubbleIntoView(root: root)
        }
    }

    private func bringOneBubbleIntoView(root: Entity) {
        let bubbleEntities = root.allDescendants().filter { $0.name.hasPrefix("MessageBubble-") }
        guard let first = bubbleEntities.first else { return }

        // 카메라 앞에 랜덤 배치
        let distance = SpaceBubblePositionPolicy.minDistanceFromCenter
        let x = Float.random(in: SpaceBubblePositionPolicy.minXPosition...SpaceBubblePositionPolicy.maxXPosition)
        AppLog.debug("\(x)", category: .space)
        let y = Float.random(in: SpaceBubblePositionPolicy.minYPosition...SpaceBubblePositionPolicy.maxYPosition)
        let z = rotationCamera.position.z - distance

        first.position = SIMD3<Float>(x, y, z)
    }
}

// MARK: - Camera Input

extension SpaceController {
    func handleDrag(_ translation: CGSize) {
        rotationCamera.handleDrag(
            translationX: Float(
                translation.width
            ),
            translationY: Float(
                translation.height
            )
        )
    }

    func endDrag() {
        rotationCamera.endDrag()
    }
}

private extension Entity {
    func allDescendants() -> [Entity] {
        var descendants: [Entity] = []

        for child in children {
            descendants.append(child)
            descendants.append(contentsOf: child.allDescendants())
        }

        return descendants
    }
}
