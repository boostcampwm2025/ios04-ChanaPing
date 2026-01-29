//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

struct SpaceView: View {

    @EnvironmentObject private var locationProvider: LocationProvider
    @StateObject private var store: SpaceStore

    @State private var domeEnvironment: DomeEnvironment
    @State private var rotationCamera: RotationCamera

    @State private var spaceRootEntity: Entity?
    @State private var messageBubbleTemplateEntity: Entity?

    @State private var syncTask: Task<Void, Never>?
    @State private var bubbleSynchronizer = SpaceMessageBubbleSynchronizer()

    private let place: Place
    private let onNavigate: (Coordinate, Place) -> Void

    init(
        store: SpaceStore,
        domeEnvironment: DomeEnvironment,
        place: Place,
        onNavigate: @escaping (Coordinate, Place) -> Void
    ) {
        _store = StateObject(wrappedValue: store)
        _rotationCamera = State(
            initialValue: RotationCamera(
                position: .init(x: 0, y: 0.7, z: 0),    // 카메라 시작 위치 (돔 중심에서 약간 위)
                rotateSensitivity: 0.003                // 회전 민감도 (값이 클수록 더 빠르게 회전)
            )
        )
        _domeEnvironment = State(initialValue: domeEnvironment)
        self.place = place
        self.onNavigate = onNavigate
    }

    var body: some View {
        ZStack {
            RealityView { content in
                // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
                content.camera = .virtual
                configureSpace(content: content)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        AppLog.debug(
                            "Drag changed: start=\(value.startLocation) loc=\(value.location) translation=\(value.translation)",
                            category: .space
                        )
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
                        if let coordinate = locationProvider.current {
                            onNavigate(coordinate, store.place)
                        }
                    }
                }
                .padding(.bottom, 96)
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
                configureGroundSurface(domeEntity: domeEntity)

                // 메시지 버블 로드
                let messageEntity = try await Entity(named: "Message.usdz")
                messageEntity.name = "MessageBubble"

                await MainActor.run {
                    messageBubbleTemplateEntity = messageEntity
                    let snapshot = store.state.messages
                    syncIfPossible(messages: snapshot)
                }

                // 카메라 추가
                AppLog.debug("RotationCamera: will add to scene", category: .space)
                rotationCamera.addToScene(content)
                AppLog.debug("RotationCamera: did add to scene", category: .space)
            } catch {
                AppLog.error(
                    "Failed to load dome entity",
                    category: .space,
                    error: error
                )
            }
        }
    }

    private func configureShaderMaterial(
        on parent: Entity,
        surfaceName: String,
        category: LogCategory = .resource,
        configure: (inout ShaderGraphMaterial) throws -> Void
    ) {
        guard let surfaceEntity = parent.findEntity(named: surfaceName) else {
            AppLog.warn(
                "Surface entity '\(surfaceName)' not found",
                category: category
            )
            return
        }

        guard
            let model = surfaceEntity.components[ModelComponent.self],
            var material = model.materials.first as? ShaderGraphMaterial
        else {
            AppLog.warn(
                "ShaderGraphMaterial not found on '\(surfaceName)'",
                category: category
            )
            return
        }

        do {
            try configure(&material)
            surfaceEntity.components[ModelComponent.self]?.materials = [material]
        } catch {
            AppLog.error(
                "Failed to configure material on '\(surfaceName)'",
                category: category,
                error: error
            )
        }
    }

    private func configureDomeSurface(domeEntity: Entity) {
        let gradientPair = DomeColor.colors(for: domeEnvironment.dayPart)

        configureShaderMaterial(
            on: domeEntity,
            surfaceName: "Dome_01",
            category: .resource
        ) { material in
            try material.setParameter(
                name: "topColor",
                value: .color(gradientPair.top)
            )

            try material.setParameter(
                name: "bottomColor",
                value: .color(gradientPair.bottom)
            )
        }
    }

    private func configureGroundSurface(domeEntity: Entity) {
        let gradientPair = DomeColor.colors(for: domeEnvironment.dayPart)

        configureShaderMaterial(
            on: domeEntity,
            surfaceName: "Ground_01",
            category: .resource
        ) { material in
            try material.setParameter(
                name: "topColor",
                value: .color(gradientPair.top)
            )

            try material.setParameter(
                name: "bottomColor",
                value: .color(gradientPair.bottom)
            )

            try material.setParameter(name: "Density", value: .float(0.6))
            try material.setParameter(name: "Contrast", value: .float(0.2))
            try material.setParameter(name: "TimeSpeed", value: .float(0.3))
        }
    }

}

// MARK: - Message Bubble UI (말풍선/텍스트 생성)

extension SpaceView {
    private func syncIfPossible(messages: [Message]) {
        guard let root = spaceRootEntity else { return }
        guard let template = messageBubbleTemplateEntity else { return }

        syncTask?.cancel()

        syncTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            bubbleSynchronizer.sync(
                to: root,
                messages: messages,
                templateEntity: template
            )
        }
    }
}

#Preview {
    NavigationStack {
        SpaceView(
            store: .init(
                fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                place: .init(
                    id: .init(value: .init()),
                    name: "광화문",
                    coordinate: .init(latitude: 0, longitude: 0)
                )
            ),
            domeEnvironment: .init(dayPart: .afternoon),
            place: .init(
                id: .init(value: .init()),
                name: "광화문",
                coordinate: .init(latitude: 0, longitude: 0)
            ),
            onNavigate: { _, _ in }
        )
    }
}
