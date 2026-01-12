//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

struct SpaceView: View {

    @StateObject private var store = SpaceViewStore()
    @State private var domeEnvironment: DomeEnvironment
    @State private var spaceRootEntity: Entity?
    @State private var didAddMessageBubbles = false

    private let rotationCamera = RotationCamera(
        position: .init(x: 0, y: 0.7, z: 0),
        rotateSensitivity: 0.003
    )

    init(environment: DomeEnvironment) {
        self.domeEnvironment = environment
    }

    var body: some View {
        RealityView { content in
            // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
            content.camera = .virtual
            configureSpace(content: content)
        } update: { _ in
            // messages 로드 완료 + 루트 준비 + 아직 생성 전 => 생성
            guard didAddMessageBubbles == false else { return }
            guard let root = spaceRootEntity else { return }
            guard store.state.messages.isEmpty == false else { return }

            addMessageBubbles(to: root, messages: store.state.messages)

            Task { @MainActor in
                didAddMessageBubbles = true
            }
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
        .task {
            await store.send(intent: .onAppear)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                MessageComposeView()
            } label: {
                WriteButton { }
                    .disabled(true)
            }
        }
    }
}

// MARK: - Dome UI

extension SpaceView {
    private func configureSpace(content: RealityViewCameraContent) {
        guard spaceRootEntity == nil else { return }

        Task {
            do {
                // 0) SpaceRoot 생성 + 보관
                let root = Entity()
                root.name = "SpaceRoot"
                content.add(root)

                await MainActor.run {
                    spaceRootEntity = root
                }

                // 1. 배경 돔 로드
                let domeEntity = try await Entity(named: "Dome.usdz")
                domeEntity.name = "Dome"
                root.addChild(domeEntity)
                configureDomeSurface(domeEntity: domeEntity)

                // 2. 카메라 추가
                rotationCamera.addToScene(content)
            } catch {
                print("돔 로드 실패: \(error)")
            }
        }
    }

    private func configureDomeSurface(domeEntity: Entity) {
        guard let surfaceEntity = domeEntity.findEntity(named: "Dome_01") else {
            print("Dome_01을 찾을 수 없음")
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
                print("material을 찾을 수 없음: \(error)")
            }
        }
    }
}

// MARK: - Message Bubble UI

extension SpaceView {
    private enum BubbleSizingTuning {
        static let textScale: Float = 0.60              // 모든 텍스트 동일 스케일
        static let insetRatio: Float = 1.25             // 텍스트보다 버블이 조금 더 크게(여유)
        static let minRadius: Float = 0.05              // 최소 버블 크기
        static let maxRadius: Float = 0.22              // 최대 버블 크기(너무 커지는 것 방지)
        static let textForwardPadding: Float = 0.01
        static let textContainerWidth: Float = 0.55
        static let textContainerHeight: Float = 0.18
    }

    private func addMessageBubbles(to root: Entity, messages: [SpaceMessage]) {
        let placer = BubblePlacer()

        for message in messages {
            // 텍스트 먼저 생성 (스케일 고정)
            let processed = forceTwoLinesNoEllipsis(message.text)
            let textEntity = makeTextEntity(processed)

            // 중앙 정렬 보정
            centerTextEntity(textEntity)

            // 텍스트 크기 기반으로 버블 반지름 계산
            let bubbleRadius = bubbleRadiusToFitText(textEntity)

            // 반지름 기반으로 버블 생성
            var bubbleMaterial = SimpleMaterial()
            bubbleMaterial.color = .init(tint: .white.withAlphaComponent(0.18), texture: nil)
            bubbleMaterial.roughness = .float(0.05) // 표면 매끈 → 하이라이트 또렷
            bubbleMaterial.metallic = .float(0.0)   // 금속 아님

            // 반지름 기반 버블 생성
            let marker = ModelEntity(
                mesh: .generateSphere(radius: bubbleRadius),
                materials: [bubbleMaterial]
            )

            // Billboard pivot + 텍스트 부착
            let billboardPivot = Entity()
            billboardPivot.components.set(BillboardComponent()) // 항상 카메라를 향함
            marker.addChild(billboardPivot)
            billboardPivot.addChild(textEntity)

            // 텍스트를 버블 반지름 기준으로 앞쪽에 배치
            textEntity.position += SIMD3<Float>(0, 0, bubbleRadius + BubbleSizingTuning.textForwardPadding)

            // 위치/이름 세팅
            marker.name = "MessageBubble-\(message.id.uuidString)"
            marker.position = placer.randomPositionInsideHemisphere(
                radiusRange: 1.4...1.7,
                yRange: 0.5...1.1,
                minimumDistanceFromCenter: 1.3,
                minimumDistanceFromViewAxis: 0.25,
                maxAttempts: 60
            )

            root.addChild(marker)
        }
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
        material.color = .init(tint: .black.withAlphaComponent(1.0), texture: nil)
        material.roughness = .float(1.0)
        material.metallic = .float(0.0)

        let textEntity = ModelEntity(mesh: mesh, materials: [material])

        // 메시지 텍스트 크기 조절
        textEntity.scale = SIMD3<Float>(repeating: BubbleSizingTuning.textScale)

        return textEntity
    }

    private func bubbleRadiusToFitText(_ textEntity: ModelEntity) -> Float {
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let extents = bounds.extents

        // 텍스트를 감싸는 구의 반지름(대각선 기준)
        let textBoundingRadius =
        0.5 * sqrt(
            extents.x * extents.x +
            extents.y * extents.y +
            extents.z * extents.z
        )

        let padded = textBoundingRadius * BubbleSizingTuning.insetRatio
        let clamped = min(max(padded, BubbleSizingTuning.minRadius), BubbleSizingTuning.maxRadius)
        return clamped
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

    private func forceTwoLinesNoEllipsis(_ text: String) -> String {
        let words = text.split(separator: " ").map(String.init)

        if text.count >= 10 && words.count >= 2 {
            // 총 길이를 반으로 나눠서 가장 균형 좋은 지점 찾기
            let target = text.count / 2

            var bestIndex = 1
            var bestDiff = Int.max
            var prefixCount = 0

            for i in 1..<words.count {
                // i개 단어를 첫 줄에 넣었을 때 길이
                prefixCount = words[0..<i].joined(separator: " ").count
                let diff = abs(prefixCount - target)
                if diff < bestDiff {
                    bestDiff = diff
                    bestIndex = i
                }
            }

            let first = words[0..<bestIndex].joined(separator: " ")
            let second = words[bestIndex...].joined(separator: " ")

            return "\(first)\n\(second)"
        }

        return text
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
            let theta = Float.random(in: 0...(2 * .pi))
            let y = Float.random(in: yRange)
            let radius = Float.random(in: radiusRange)

            let xzLimit = max(0.0, sqrt(max(0.0, radius * radius - y * y)))
            let x = cos(theta) * xzLimit
            let z = sin(theta) * xzLimit

            let position = SIMD3<Float>(x, y, z)

            // 1) 중심 근처 피하기
            if simd_length(position) < minimumDistanceFromCenter {
                continue
            }

            // 2) 뷰 축(카메라 방향 축) 근처 피하기
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
        SpaceView(environment: .init(weather: .sunny, dayPart: .afternoon))
    }
}
