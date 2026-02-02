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
                AppLog.debug("S1. Camera added", category: .space)
                rotationCamera.addToScene(content)

                // SpaceRoot 생성: 돔/버블 오브젝트를 한 곳에 묶는 컨테이너
                AppLog.debug("S2. SpaceRoot created", category: .space)
                let root = Entity()
                root.name = "SpaceRoot"
                content.add(root)

                spaceRootEntity = root

                // Dome 로드
                AppLog.debug("S3. Dome loaded", category: .space)
                let domeEntity = try await Entity(named: "Dome.usdz")
                domeEntity.name = "Dome"
                self.domeEntity = domeEntity

                // 머테리얼 세팅
                if let domeEnvironment = domeEnvironment {
                    AppLog.debug("S4. Materials configured", category: .space)
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
                AppLog.debug("S5. Message template loaded", category: .space)
                let messageEntity = try await Entity(named: "Message.usdz")
                messageEntity.name = "MessageBubble"

                materialConfigurator.configureMessage(messageEntity: messageEntity)

                // 터치 이벤트 수신을 위해 InputTargetComponent 추가
                messageEntity.components.set(InputTargetComponent())

                messageBubbleTemplateEntity = messageEntity

                didFinishConfigure = true
                isConfiguring = false
                flushReadyHandlers()

                trySyncIfPossible()
            } catch {
                isConfiguring = false
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
        AppLog.debug("SpaceController sync: \(messages.count)", category: .space)

        pendingMessages = messages
        trySyncIfPossible()
    }

    func update(domeEnvironment: DomeEnvironment) {
        self.domeEnvironment = domeEnvironment

        guard let domeEntity else { return }

        // 머테리얼 업데이트
        AppLog.debug("Dome Materials updated", category: .space)
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
        guard let root = spaceRootEntity else {
            AppLog.debug("trySync blocked: root is nil", category: .space)
            return
        }
        guard let template = messageBubbleTemplateEntity else {
            AppLog.debug("trySync blocked: template is nil", category: .space)
            return
        }

        let snapshot = pendingMessages

        syncTask?.cancel()
        syncTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            bubbleSynchronizer.sync(
                to: root,
                messages: snapshot,
                templateEntity: template
            )
        }

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
