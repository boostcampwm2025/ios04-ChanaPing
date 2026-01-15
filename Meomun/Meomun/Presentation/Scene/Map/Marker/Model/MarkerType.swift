//
//  MarkerType.swift
//  Meomun
//
//  Created by MinwooJe on 1/15/26.
//

/// 지도 마커의 종류를 정의하는 enum
/// 메시지 개수와 종류에 따라 마커 타입이 결정됩니다.
enum MarkerType {
    /// 단일 메시지 버블 (메시지 1개)
    case singleBubble(Message)

    /// 회전 버블 (장소 메시지 2개 이상)
    case rotatingBubble([Message])

    /// 스택 버블 (좌표 메시지 2개 이상)
    case stackBubble([Message])

    /// 메시지 배열과 장소 태그 유무로부터 MarkerType을 결정합니다.
    /// - Returns: 메시지가 없으면 nil, 있으면 적절한 MarkerType
    static func from(messages: [Message], isPlace: Bool) -> MarkerType? {
        guard !messages.isEmpty else { return nil }

        if messages.count == 1 {
            return .singleBubble(messages[0])
        }

        return isPlace ? .rotatingBubble(messages) : .stackBubble(messages)
    }
}
