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
    private var domeEnvironment: DomeEnvironment
    private var rotationCamera: RotationCamera

    private var spaceRootEntity: Entity?
    private var messageBubbleTemplateEntity: Entity?
    private var syncTask: Task<Void, Never>?
    private var pendingMessages: [Message] = []

    private let bubbleSynchronizer: SpaceMessageBubbleSynchronizer
    private let materialConfigurator: SpaceMaterialConfigurator

    init(
        domeEnvironment: DomeEnvironment,
        rotationCamera: RotationCamera = .init(
            position: .init(x: 0, y: 0.7, z: 0),
            rotateSensitivity: 0.003
        )
    ) {
        self.domeEnvironment = domeEnvironment
        self.rotationCamera = rotationCamera
        self.bubbleSynchronizer = SpaceMessageBubbleSynchronizer()
        self.materialConfigurator = SpaceMaterialConfigurator()
    }

    // MARK: - Space Setup
    func configureSpace(content: RealityViewCameraContent) {
        guard spaceRootEntity == nil else { return }

        Task {
            do {
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
                root.addChild(domeEntity)

                // Message template 로드
                AppLog.debug("S4. Message template loaded", category: .space)
                let messageEntity = try await Entity(named: "Message.usdz")
                messageEntity.name = "MessageBubble"

                // 터치 이벤트 수신을 위해 InputTargetComponent 추가
                messageEntity.components.set(InputTargetComponent())

                messageBubbleTemplateEntity = messageEntity
                trySyncIfPossible()

                // 머테리얼 세팅
                AppLog.debug("S5. Materials configured", category: .space)
                materialConfigurator.configureDome(
                    domeEntity: domeEntity,
                    dayPart: domeEnvironment.dayPart
                )
                materialConfigurator.configureGround(
                    domeEntity: domeEntity,
                    dayPart: domeEnvironment.dayPart
                )
            } catch {
                AppLog.error(
                    "Failed to configure Space scene",
                    category: .space,
                    error: error
                )
            }
        }
    }
}

// MARK: - Message Sync
extension SpaceController {
    func sync(messages: [Message]) {
        AppLog.debug("SpaceController sync: \(messages.count)", category: .space)

        pendingMessages = messages
        trySyncIfPossible()
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
