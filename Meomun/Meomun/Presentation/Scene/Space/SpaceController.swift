//
//  SpaceController.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit
import SwiftUI
import CoreMotion

@MainActor
final class SpaceController {
    private var domeEnvironment: DomeEnvironment?
    private var rotationCamera: RotationCamera

    // MARK: - Gyro
    private let motionManager = CMMotionManager()
    private var isGyroEnabled: Bool = false
    private var gyroBaseAttitude: simd_quatf?
    private var gyroBaseCameraOrientation: simd_quatf?
    private var gyroUpdateTask: Task<Void, Never>?

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

    deinit {
        motionManager.stopDeviceMotionUpdates()
        gyroUpdateTask?.cancel()
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

    func selectMessage(_ messageID: MessageID?) {
        bubbleSynchronizer.applySelection(selectedID: messageID)
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
        let y = Float.random(in: SpaceBubblePositionPolicy.minYPosition...SpaceBubblePositionPolicy.maxYPosition)
        let z = rotationCamera.position.z - distance

        first.position = SIMD3<Float>(x, y, z)
    }
}

// MARK: - Camera Input

extension SpaceController {
    func handleDrag(_ translation: CGSize) {
        rotationCamera.handleDrag(
            translationX: Float(translation.width),
            translationY: Float(translation.height)
        )
    }

    func endDrag() {
        rotationCamera.endDrag()
    }

    func setGyroEnabled(_ isEnabled: Bool) {
        guard isEnabled != isGyroEnabled else { return }
        isGyroEnabled = isEnabled

        if isEnabled {
            startGyroUpdates()
        } else {
            stopGyroUpdates()

            rotationCamera.syncDragAnglesFromCurrentOrientation()
        }
    }

    private func startGyroUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            AppLog.debug("DeviceMotion 비활성화 상태 (혹은 시뮬레이터)", category: .space)
            return
        }

        // Baseline 초기화
        gyroBaseAttitude = nil
        gyroBaseCameraOrientation = rotationCamera.orientation

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)

        gyroUpdateTask?.cancel()
        gyroUpdateTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                if let attitude = self.motionManager.deviceMotion?.attitude {
                    let current = self.simdQuat(from: attitude.quaternion)

                    if self.gyroBaseAttitude == nil {
                        self.gyroBaseAttitude = current
                    } else if let baseAttitude = self.gyroBaseAttitude,
                              let baseCamera = self.gyroBaseCameraOrientation {
                        let delta = current * baseAttitude.inverse
                        let target = baseCamera * delta

                        self.rotationCamera.setOrientation(target)
                    }
                }

                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopGyroUpdates() {
        gyroUpdateTask?.cancel()
        gyroUpdateTask = nil
        gyroBaseAttitude = nil
        gyroBaseCameraOrientation = nil
        motionManager.stopDeviceMotionUpdates()
    }

    private func simdQuat(from quat: CMQuaternion) -> simd_quatf {
        simd_quatf(ix: Float(quat.x), iy: Float(quat.y), iz: Float(quat.z), r: Float(quat.w))
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
