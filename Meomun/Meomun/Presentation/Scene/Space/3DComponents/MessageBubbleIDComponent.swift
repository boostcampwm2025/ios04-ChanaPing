//
//  MessageBubbleIDComponent.swift
//  Meomun
//
//  Created by MinwooJe on 1/30/26.
//

import RealityKit

/// 메시지 버블 엔티티에 연결된 MessageID를 저장하는 컴포넌트
/// SpatialTapGesture로 터치된 엔티티에서 MessageID를 타입 세이프하게 추출하기 위해 사용
struct MessageBubbleIDComponent: Component {
    let messageID: MessageID
}
