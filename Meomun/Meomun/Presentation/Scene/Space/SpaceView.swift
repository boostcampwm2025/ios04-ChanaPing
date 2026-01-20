//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

fileprivate enum Constants {
    static let successMessage = "머문 흔적을 남겼어요."
}

struct SpaceView: View {

    @EnvironmentObject private var locationProvider: LocationProvider
    @StateObject private var store: SpaceStore
    @State private var domeEnvironment: DomeEnvironment

    @State private var spaceRootEntity: Entity?
    @State private var messageBubbleTemplateEntity: Entity?

    @State private var messageBubbleRootByID: [MessageID: Entity] = [:]

    @State private var syncTask: Task<Void, Never>?

    private let place: Place

    private let rotationCamera = RotationCamera(
        position: .init(x: 0, y: 0.7, z: 0),    // 카메라 시작 위치 (돔 중심에서 약간 위)
        rotateSensitivity: 0.003                // 회전 민감도 (값이 클수록 더 빠르게 회전)
    )

    init(store: SpaceStore, domeEnvironment: DomeEnvironment, place: Place) {
        _store = StateObject(wrappedValue: store)
        self.domeEnvironment = domeEnvironment
        self.place = place
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RealityView { content in
                    // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
                    content.camera = .virtual
                    configureSpace(content: content)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationCamera.handleDrag(
                                translationX: Float(value.translation.width),
                                translationY: Float(value.translation.height)
                            )
                        }
                        .onEnded { _ in
                            rotationCamera.endDrag()
                        }
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        WriteButton {   // TODO: - 위치 조정 필요
                            Task { await store.send(intent: .tapWriteButton) }
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 96)
                }
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { store.state.isShowingAddMessage },
                    set: { isPresented in
                        if !isPresented {
                            Task { await store.send(intent: .dismissAddMessage) }
                        }
                    }
                )
            ) {
                if let coordinate = store.state.userLocation {
                    MessageComposerView(
                        store: MessageComposerStore(
                            userLocation: coordinate,
                            createMessage: CreateMessageUseCaseImpl(
                                messageRepository: MessageRepositoryImpl()
                            ),
                            onClose: { isSuccess in
                                Task {
                                    await store.send(intent: .dismissAddMessage)

                                    if isSuccess {
                                        await store.send(intent: .setToast(Constants.successMessage))
                                    }
                                }
                            }
                        )
                    )
                }
            }
        }
        .task {
            await store.send(intent: .onAppear(placeID: place.id))
        }
        .onChange(of: store.state.messages.map(\.id)) {
            let snapshot = store.state.messages
            syncIfPossible(messages: snapshot)
        }
    }
}

// MARK: - Dome UI (배경 돔 로딩/표현)

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        guard spaceRootEntity == nil else { return }

        Task {
            do {
                // SpaceRoot 생성: 돔/버블 오브젝트를 한 곳에 묶는 컨테이너
                let root = Entity()
                root.name = "SpaceRoot"
                content.add(root)

                await MainActor.run {
                    spaceRootEntity = root
                }

                // 돔 배경 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                domeEntity.name = "Dome"
                root.addChild(domeEntity)
                configureDomeSurface(domeEntity: domeEntity)

                // 메시지 버블 로드
                let messageEntity = try await Entity(named: "Message.usdz")
                messageEntity.name = "MessageBubble"

                await MainActor.run {
                    messageBubbleTemplateEntity = messageEntity
                    let snapshot = store.state.messages
                    syncIfPossible(messages: snapshot)
                }

                // 카메라 추가
                rotationCamera.addToScene(content)
            } catch {
                AppLog.error(
                    "Failed to load dome entity",
                    category: .space,
                    error: error
                )
            }
        }
    }

    private func configureDomeSurface(domeEntity: Entity) {
        guard let surfaceEntity = domeEntity.findEntity(named: "Dome_01") else {
            AppLog.warn(
                "Dome surface entity 'Dome_01' not found",
                category: .resource
            )
            return
        }

        if var material = surfaceEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
            let gradientPair = DomeColor.colors(for: domeEnvironment.dayPart)

            do {
                try material.setParameter(
                    name: "topColor",
                    value: .color(gradientPair.top)
                )

                try material.setParameter(
                    name: "bottomColor",
                    value: .color(gradientPair.bottom)
                )

                surfaceEntity.components[ModelComponent.self]?.materials = [material]
            } catch {
                AppLog.error(
                    "Failed to configure dome material",
                    category: .resource,
                    error: error
                )
            }
        }
    }
}

// MARK: - Message Bubble UI (말풍선/텍스트 생성)

extension SpaceView {
    private enum BubbleSizingTuning {
        static let baseBubbleScale: Float = 0.10                    // 버블 스케일 표준
        static let textScale: Float = 0.50                          // 텍스트 엔티티 스케일
        static let paddingX: Float = 0.10                           // 텍스트 좌우 여백
        static let paddingY: Float = 0.02                           // 텍스트 상하 여백
        static let minUniform: Float = 0.85                         // 버블 최소 크기 제한
        static let maxUniform: Float = 2.2                          // 버블 최대 크기 제한
        static let textContainerWidth: Float = 0.55                 // 텍스트 최대 넓이
        static let textContainerHeight: Float = 0.18                // 텍스트 최대 높이
        static let statusLineHeight: Float = 0.006                  // 상태 라인 두께
        static let statusLineWidthRatioToBubble: Float = 0.20       // 버블 폭 대비 라인 폭 비율
        static let statusLineTopInsetRatioToBubble: Float = 0.20    // 버블 상단에서 아래로 내릴 비율
        static let entityForwardPadding: Float = 0.01               // 텍스트보다 약간 앞(z+)으로
        static let recentThresholdSeconds: TimeInterval = 20 * 60
    }

    private func syncIfPossible(messages: [Message]) {
        guard let root = spaceRootEntity else { return }
        guard messageBubbleTemplateEntity != nil else { return }

        syncTask?.cancel()

        syncTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            syncMessageBubbles(to: root, messages: messages)
        }
    }

    private func syncMessageBubbles(to root: Entity, messages: [Message]) {
        guard let messageBubbleTemplateEntity = messageBubbleTemplateEntity else { return }

        let incomingMessageIDSet = Set(messages.map(\.id))
        let existingMessageIDSet = Set(messageBubbleRootByID.keys)
        let messageIDSetToRemove = existingMessageIDSet.subtracting(incomingMessageIDSet)
        let messageIDSetToAdd = incomingMessageIDSet.subtracting(existingMessageIDSet)

        for messageID in messageIDSetToRemove {
            removeMessageBubble(messageID: messageID)
        }

        for messageID in messageIDSetToAdd {
            guard let message = messages.first(where: { $0.id == messageID }) else { continue }

            addMessageBubble(
                to: root,
                message: message,
                messageBubbleTemplateEntity: messageBubbleTemplateEntity
            )
        }
    }

    private func removeMessageBubble(messageID: MessageID) {
        guard let bubbleRootEntity = messageBubbleRootByID[messageID] else { return }
        bubbleRootEntity.removeFromParent()
        messageBubbleRootByID[messageID] = nil
    }

    private func addMessageBubble(to root: Entity, message: Message, messageBubbleTemplateEntity: Entity) {
        let bubblePlacer = BubblePlacer()

        // 텍스트 가공 및 생성
        let processedText = arrangeText(message.content)
        let textEntity = makeTextEntity(processedText)

        // 중앙 정렬 보정
        centerTextEntity(textEntity)

        // 버블 루트 (전체 billboard 대상)
        let bubbleRootEntity = Entity()
        bubbleRootEntity.name = "MessageBubble-\(message.id.value.uuidString)"
        bubbleRootEntity.components.set(BillboardComponent())

        // 버블 랜덤 배치
        bubbleRootEntity.position = bubblePlacer.randomPositionInsideHemisphere(
            radiusRange: 1.4...1.7,
            yRange: 0.5...1.1,
            minimumDistanceFromCenter: 1.3,
            minimumDistanceFromViewAxis: 0.25,
            maxAttempts: 60
        )

        // messageBubbleTemplateEntity 복제
        let bubbleBubbleEntity = messageBubbleTemplateEntity.clone(recursive: true)
        bubbleBubbleEntity.name = "MessageModel-\(message.id.value.uuidString)"

        // 텍스트에 맞는 uniform 배율 계산
        let multiplier = uniformMultiplierToFitText(
            textEntity: textEntity,
            bubbleEntity: messageBubbleTemplateEntity
        )

        // 엔티티 크기 조절
        let finalScale = BubbleSizingTuning.baseBubbleScale * multiplier
        bubbleBubbleEntity.scale = SIMD3<Float>(repeating: finalScale)

        // Entity 계층 구성: (루트) - (버블) + (텍스트)
        bubbleRootEntity.addChild(bubbleBubbleEntity)
        bubbleRootEntity.addChild(textEntity)

        // 텍스트를 버블 앞쪽으로 배치
        placeTextInFrontOfBubble(textEntity, bubbleEntity: bubbleBubbleEntity)

        // 최근/일반 메시지 상태 라인 추가 (버블 내부)
        let isRecent = isRecentMessage(message)
        attachStatusLine(to: bubbleRootEntity, bubbleEntity: bubbleBubbleEntity, isRecent: isRecent)

        // 씬에 추가
        root.addChild(bubbleRootEntity)

        // 추적 저장
        messageBubbleRootByID[message.id] = bubbleRootEntity
    }

    private func arrangeText(_ text: String) -> String {
        let words = text.split(separator: " ").map(String.init)

        if text.count >= 10 && words.count >= 2 {
            let target = text.count / 2
            var bestIndex = 1
            var bestDiff = Int.max
            var prefixCount = 0

            for index in 1..<words.count {
                // index 개 단어를 첫 줄에 넣었을 때 길이
                prefixCount = words[0..<index].joined(separator: " ").count
                let diff = abs(prefixCount - target)

                if diff < bestDiff {
                    bestDiff = diff
                    bestIndex = index
                }
            }

            let first = words[0..<bestIndex].joined(separator: " ")
            let second = words[bestIndex...].joined(separator: " ")

            return "\(first)\n\(second)"
        }

        return text
    }

    private func makeTextEntity(_ text: String) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.05, weight: .semibold),
            containerFrame: CGRect(
                x: 0,
                y: 0,
                width: CGFloat(BubbleSizingTuning.textContainerWidth),
                height: CGFloat(BubbleSizingTuning.textContainerHeight)
            ),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        var material = SimpleMaterial()
        material.color = .init(tint: .black.withAlphaComponent(0.95), texture: nil)
        material.roughness = .float(1.0)
        material.metallic = .float(0.0)

        let textEntity = ModelEntity(mesh: mesh, materials: [material])

        // 메시지 텍스트 크기 조절
        textEntity.scale = SIMD3<Float>(repeating: BubbleSizingTuning.textScale)

        return textEntity
    }

    private func centerTextEntity(_ textEntity: ModelEntity) {
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let center = bounds.center

        // 텍스트 로컬 중심을 원점으로 오게 보정
        textEntity.position = SIMD3<Float>(
            -center.x,
            -center.y,
            -center.z
        )
    }

    private func uniformMultiplierToFitText(textEntity: ModelEntity, bubbleEntity: Entity) -> Float {
        let textBounds = textEntity.visualBounds(relativeTo: nil)
        let text = textBounds.extents

        let base = bubbleBaseSize(entity: bubbleEntity)
        let baseWidth = max(base.x, 0.0001)
        let baseHeight = max(base.y, 0.0001)

        let neededWidth = text.x + BubbleSizingTuning.paddingX
        let neededHeight = text.y + BubbleSizingTuning.paddingY

        let widthMultiplier = neededWidth / baseWidth
        let heightMultiplier = neededHeight / baseHeight

        let raw = max(widthMultiplier, heightMultiplier)

        return min(max(raw, BubbleSizingTuning.minUniform), BubbleSizingTuning.maxUniform)
    }

    private func bubbleBaseSize(entity: Entity) -> SIMD2<Float> {
        let bubble = entity.clone(recursive: true)
        bubble.scale = SIMD3<Float>(repeating: BubbleSizingTuning.baseBubbleScale)

        let bounds = bubble.visualBounds(relativeTo: nil)
        let extents = bounds.extents

        return SIMD2<Float>(extents.x, extents.y)
    }

    private func placeTextInFrontOfBubble(_ textEntity: ModelEntity, bubbleEntity: Entity) {
        let bounds = bubbleEntity.visualBounds(relativeTo: nil)
        let extents = bounds.extents

        // 모델의 ‘두께(깊이)’ 절반 정도 + 패딩만큼 앞으로
        let frontOffset = (extents.z * 0.5) + BubbleSizingTuning.entityForwardPadding

        textEntity.position += SIMD3<Float>(0, 0, frontOffset)
    }

    private func isRecentMessage(_ message: Message, now: Date = .now) -> Bool {
        now.timeIntervalSince(message.createdAt) < BubbleSizingTuning.recentThresholdSeconds
    }

    private func attachStatusLine(
        to bubbleRootEntity: Entity,
        bubbleEntity: Entity,
        isRecent: Bool
    ) {
        // 최근/일반 전환 대응
        for child in bubbleRootEntity.children where child.name == "StatusLine" {
            child.removeFromParent()
        }

        // 버블 bounds를 기준으로 라인 폭/위치 계산
        let bubbleBounds = bubbleEntity.visualBounds(relativeTo: nil)
        let bubbleExtents = bubbleBounds.extents

        let lineWidth = bubbleExtents.x * BubbleSizingTuning.statusLineWidthRatioToBubble
        let lineEntity = makeStatusLineEntity(isRecent: isRecent, width: lineWidth)

        let lineY = (bubbleExtents.y * 0.5) - (bubbleExtents.y * BubbleSizingTuning.statusLineTopInsetRatioToBubble)
        let lineZ = (bubbleExtents.z * 0.5) + BubbleSizingTuning.entityForwardPadding

        lineEntity.position = SIMD3<Float>(0, lineY, lineZ)
        bubbleRootEntity.addChild(lineEntity)
    }

    private func makeStatusLineEntity(isRecent: Bool, width: Float) -> ModelEntity {
        let mesh = MeshResource.generatePlane(
            width: max(width, 0.001),
            height: BubbleSizingTuning.statusLineHeight,
            cornerRadius: BubbleSizingTuning.statusLineHeight * 0.5
        )

        let tint: UIColor = isRecent ? .orange : .blue
        var material = SimpleMaterial()
        material.color = .init(tint: tint, texture: nil)
        material.roughness = .float(0.1)
        material.metallic = .float(0.0)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "StatusLine"
        return entity
    }
}

// MARK: - BubblePlacer

private struct BubblePlacer {
    func randomPositionInsideHemisphere(
        radiusRange: ClosedRange<Float>,
        yRange: ClosedRange<Float>,
        minimumDistanceFromCenter: Float,
        minimumDistanceFromViewAxis: Float,
        maxAttempts: Int
    ) -> SIMD3<Float> {
        for _ in 0..<maxAttempts {
            let theta = Float.random(in: 0...(2 * .pi)) // 수평 회전 각도 (0~360도)
            let y = Float.random(in: yRange)            // 높이 범위 (바닥에 너무 붙지 않도록 yRange로 제한)
            let radius = Float.random(in: radiusRange)  // 중심에서 떨어지는 거리 (돔 내부에서 "멀리/가까이" 범위)

            let xzLimit = max(0.0, sqrt(max(0.0, radius * radius - y * y)))
            let x = cos(theta) * xzLimit
            let z = sin(theta) * xzLimit

            let position = SIMD3<Float>(x, y, z)

            // 중심 근처 피하기
            if simd_length(position) < minimumDistanceFromCenter {
                continue
            }

            // 뷰 축(카메라 방향 축) 근처 피하기
            let distanceFromViewAxis = simd_length(SIMD2<Float>(x, y))
            if distanceFromViewAxis < minimumDistanceFromViewAxis {
                continue
            }

            return position
        }

        // 실패 시 fallback
        return SIMD3<Float>(minimumDistanceFromViewAxis, yRange.upperBound, -radiusRange.upperBound)
    }
}

#Preview {
    NavigationStack {
        SpaceView(
            store: .init(
                locationProvider: .init(),
                fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                )
            ),
            domeEnvironment: .init(
                weather: .sunny,
                dayPart: .afternoon
            ),
            place: .init(
                id: .init(
                    value: .init()
                ),
                name: "광화문",
                coordinate: .init(
                    latitude: 0,
                    longitude: 0
                )
            )
        )
    }
}
