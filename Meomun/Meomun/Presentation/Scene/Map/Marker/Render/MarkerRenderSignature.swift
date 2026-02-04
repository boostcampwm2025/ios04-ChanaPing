//
//  MarkerRenderSignature.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation
struct MarkerRenderSignature: Hashable {
    enum Kind: Int, Hashable { case single, rotating, stack }

    let kind: Kind
    let firstMessageId: MessageID?      // 초기 아이콘에 쓰는 메시지(=single이면 그거, rotating/stack이면 first)
    let count: Int                  // 표시 대상(messages: suffix(displayLimit)) 개수
    let idsHash: Int                // 메시지 묶음 내용 변화 감지용
}

enum MessageMarkerRenderDecision: Equatable {
    case renderNeeded(signature: MarkerRenderSignature)
    case skipSameSignature
    case skipBecauseAnimatingAlready
}

enum MessageMarkerRenderPolicy {
    
    static func makeSignature(
        markerType: MarkerType,
        messages: [Message]
    ) -> MarkerRenderSignature {

        let kind: MarkerRenderSignature.Kind
        let firstId: MessageID?

        switch markerType {
        case .singleBubble(let message):
            kind = .single
            firstId = message.id

        case .rotatingBubble(let messages):
            kind = .rotating
            firstId = messages.first?.id

        case .stackBubble(let messages):
            kind = .stack
            firstId = messages.first?.id
        }

        let idsHash = idsHash(messages)

        return MarkerRenderSignature(
            kind: kind,
            firstMessageId: firstId,
            count: messages.count,
            idsHash: idsHash
        )
    }

    /// C. 렌더 스킵 규칙(순수)
    /// - signature가 lastSignature와 같으면 skip
    /// - rotating/stack + animationState 존재 + hasFadedIn이면 초기 렌더 스킵(애니메이션이 이미 돌고 있다고 간주)
    static func decide(
        markerType: MarkerType,
        messages: [Message],
        lastSignature: MarkerRenderSignature?,
        hasFadedIn: Bool,
        hasAnimationState: Bool
    ) -> MessageMarkerRenderDecision {

        let signature = makeSignature(markerType: markerType, messages: messages)

        if let lastSignature, lastSignature == signature {
            return .skipSameSignature
        }

        switch markerType {
        case .rotatingBubble, .stackBubble:
            if hasAnimationState && hasFadedIn {
                return .skipBecauseAnimatingAlready
            }

        case .singleBubble:
            break
        }

        return .renderNeeded(signature: signature)
    }

    private static func idsHash(_ messages: [Message]) -> Int {
        guard !messages.isEmpty else { return 0 }
        var hasher = Hasher()
        for message in messages {
            hasher.combine(message.id)
            hasher.combine(message.createdAt.timeIntervalSince1970)
        }
        return hasher.finalize()
    }
}
