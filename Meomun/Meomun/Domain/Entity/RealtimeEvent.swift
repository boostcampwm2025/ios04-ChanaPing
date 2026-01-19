//
//  RealtimeEvent.swift
//  Meomun
//
//  Created by MinwooJe on 1/13/26.
//

/// DB 실시간 변경 사항 발생 시 변경 유형을 정의합니다.
enum RealtimeEvent {
    case insert
    case delete
}

enum MessageRealtimeEvent: Sendable {
    case created(Message)           // 새 메시지 payload 전체
    case deleted(id: MessageID)     // soft delete
    case expired(id: MessageID)     // ttl 만료
    case becameStale(id: MessageID) // 20분 지나 fresh -> false
}
