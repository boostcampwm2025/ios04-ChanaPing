//
//  SpaceMessageBubbleFactory.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import RealityKit
import Foundation
import UIKit

final class SpaceMessageBubbleFactory {
    func makeBubbleRoot(message: Message, templateEntity: Entity) -> Entity {
        let bubblePlacer = BubblePlacer()

        // 텍스트 가공 및 생성
        let processedText = TextArranger.arrangeText(message.content)
        let textEntity = makeTextEntity(processedText)

        // 텍스트 중앙 정렬 보정
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
        let bubbleBubbleEntity = templateEntity.clone(recursive: true)
        bubbleBubbleEntity.name = "MessageModel-\(message.id.value.uuidString)"

        // 텍스트에 맞는 uniform 배율 계산
        let multiplier = uniformMultiplierToFitText(
            textEntity: textEntity,
            bubbleEntity: templateEntity
        )

        // 엔티티 크기 조절
        let finalScale = SpaceBubbleLayoutPolicy.baseBubbleScale * multiplier
        bubbleBubbleEntity.scale = SIMD3<Float>(repeating: finalScale)

        // Entity 계층 구성: (루트) - (버블) + (텍스트)
        bubbleRootEntity.addChild(bubbleBubbleEntity)
        bubbleRootEntity.addChild(textEntity)

        // 텍스트를 버블 앞쪽으로 배치
        placeTextInFrontOfBubble(textEntity, bubbleEntity: bubbleBubbleEntity)

        return bubbleRootEntity
    }

    private func bubbleBaseSize(entity: Entity) -> SIMD2<Float> {
        let bubble = entity.clone(recursive: true)
        bubble.scale = SIMD3<Float>(repeating: SpaceBubbleLayoutPolicy.baseBubbleScale)

        let bounds = bubble.visualBounds(relativeTo: nil)
        let extents = bounds.extents

        return SIMD2<Float>(extents.x, extents.y)
    }
}

// MARK: - Text Entity
private extension SpaceMessageBubbleFactory {
    func makeTextEntity(_ text: String) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.05, weight: .semibold),
            containerFrame: CGRect(
                x: 0,
                y: 0,
                width: CGFloat(SpaceBubbleLayoutPolicy.textContainerWidth),
                height: CGFloat(SpaceBubbleLayoutPolicy.textContainerHeight)
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
        textEntity.scale = SIMD3<Float>(repeating: SpaceBubbleLayoutPolicy.textScale)

        return textEntity
    }

    func centerTextEntity(_ textEntity: ModelEntity) {
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let center = bounds.center

        // 텍스트 로컬 중심을 원점으로 오게 보정
        textEntity.position = SIMD3<Float>(
            -center.x,
            -center.y,
            -center.z
        )
    }

    func uniformMultiplierToFitText(textEntity: ModelEntity, bubbleEntity: Entity) -> Float {
        let textBounds = textEntity.visualBounds(relativeTo: nil)
        let text = textBounds.extents

        let base = bubbleBaseSize(entity: bubbleEntity)
        let baseWidth = max(base.x, 0.0001)
        let baseHeight = max(base.y, 0.0001)

        let neededWidth = text.x + SpaceBubbleLayoutPolicy.paddingX
        let neededHeight = text.y + SpaceBubbleLayoutPolicy.paddingY

        let widthMultiplier = neededWidth / baseWidth
        let heightMultiplier = neededHeight / baseHeight

        let raw = max(widthMultiplier, heightMultiplier)

        return min(max(raw, SpaceBubbleLayoutPolicy.minUniform), SpaceBubbleLayoutPolicy.maxUniform)
    }

    func placeTextInFrontOfBubble(_ textEntity: ModelEntity, bubbleEntity: Entity) {
        let bounds = bubbleEntity.visualBounds(relativeTo: nil)
        let extents = bounds.extents

        // 모델의 ‘두께(깊이)’ 절반 정도 + 패딩만큼 앞으로
        let frontOffset = (extents.z * 0.5) + SpaceBubbleLayoutPolicy.entityForwardPadding

        textEntity.position += SIMD3<Float>(0, 0, frontOffset)
    }
}
