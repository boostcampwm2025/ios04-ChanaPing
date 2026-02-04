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
    enum BubbleTextType { case content, date }
    enum TextAlignment { case center, above, below }

    func makeBubbleRoot(
        message: Message,
        templateEntity: Entity,
        position: SIMD3<Float>
    ) -> Entity {
        let bubblePlacer = BubblePlacer()

        // 텍스트 가공 및 entity 생성
        let contentText = TextArranger.arrangeText(message.content)
        let dateText = message.displayDateString(using: AppConfig.timestampFormatter)
        let contentTextEntity = makeTextEntity(contentText, type: .content)
        let dateTextEntity = makeTextEntity(dateText, type: .date)

        // 텍스트 정렬 보정
        alignTextEntity(contentTextEntity, align: .center)
        alignTextEntity(dateTextEntity, align: .above)

        // 버블 루트 (전체 billboard 대상)
        let bubbleRootEntity = Entity()
        bubbleRootEntity.name = "MessageBubble-\(message.id.value.uuidString)"
        bubbleRootEntity.components.set(BillboardComponent())

        // 버블 랜덤 배치
        bubbleRootEntity.position = position

        // messageBubbleTemplateEntity 복제
        let bubbleBubbleEntity = templateEntity.clone(recursive: true)
        bubbleBubbleEntity.name = "MessageModel-\(message.id.value.uuidString)"

        // 텍스트에 맞는 uniform 배율 계산
        let multiplier = uniformMultiplierToFitText(
            textEntity: contentTextEntity,
            bubbleEntity: templateEntity
        )

        // 엔티티 크기 조절
        let finalScale = SpaceBubbleLayoutPolicy.baseBubbleScale * multiplier
        bubbleBubbleEntity.scale = SIMD3<Float>(repeating: finalScale)

        // 제스처 수신을 위해 버블 크기에 맞는 CollisionComponent 추가
        let collisionSize = SIMD3<Float>(
            repeating: 0.3 * finalScale / SpaceBubbleLayoutPolicy.baseBubbleScale
        )
        bubbleRootEntity.components.set(CollisionComponent(shapes: [.generateBox(size: collisionSize)]))

        // 터치 이벤트 수신을 위해 InputTargetComponent 추가
        bubbleRootEntity.components.set(InputTargetComponent())

        // MessageID 식별을 위한 ID 컴포넌트 추가
        bubbleRootEntity.components.set(MessageBubbleIDComponent(messageID: message.id))

        // Entity 계층 구성: (루트) - (버블) + (텍스트)
        bubbleRootEntity.addChild(bubbleBubbleEntity)
        bubbleRootEntity.addChild(contentTextEntity)
        bubbleRootEntity.addChild(dateTextEntity)

        // 텍스트를 버블 앞쪽으로 배치
        placeTextInFrontOfBubble(contentTextEntity, bubbleEntity: bubbleBubbleEntity)
        placeTextInFrontOfBubble(dateTextEntity, bubbleEntity: bubbleBubbleEntity)

        return bubbleRootEntity
    }

    func bubbleUniformMultiplier(message: Message, templateEntity: Entity) -> Float {
        let contentText = TextArranger.arrangeText(message.content)
        let contentTextEntity = makeTextEntity(contentText, type: .content)
        alignTextEntity(contentTextEntity, align: .center)

        return uniformMultiplierToFitText(textEntity: contentTextEntity, bubbleEntity: templateEntity)
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
    func makeTextEntity(_ text: String, type: BubbleTextType) -> ModelEntity {
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
        material.color = .init(
            tint: type == .content ? .black.withAlphaComponent(0.90) : .gray.withAlphaComponent(0.95),
            texture: nil)
        material.roughness = .float(1.0)
        material.metallic = .float(0.0)

        let textEntity = ModelEntity(mesh: mesh, materials: [material])

        // 메시지 텍스트 크기 조절
        let textEntityScale = type == .content
        ? SpaceBubbleLayoutPolicy.contentTextScale
        : SpaceBubbleLayoutPolicy.dateTextScale

        textEntity.scale = SIMD3<Float>(repeating: textEntityScale)

        return textEntity
    }

    func alignTextEntity(_ textEntity: ModelEntity, align: TextAlignment) {
        let bounds = textEntity.visualBounds(relativeTo: nil)
        let center = bounds.center

        // 텍스트 로컬 중심을 원점으로 오게 보정
        switch align {
        case .center:
            textEntity.position = SIMD3<Float>(
                -center.x,
                -center.y,
                -center.z
            )
        case .above:
            textEntity.position = SIMD3<Float>(
                -center.x,
                 -center.y + SpaceBubbleLayoutPolicy.textAlignY,
                -center.z
            )

        case .below:
            textEntity.position = SIMD3<Float>(
                -center.x,
                -center.y - SpaceBubbleLayoutPolicy.textAlignY,
                -center.z
            )
        }
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
