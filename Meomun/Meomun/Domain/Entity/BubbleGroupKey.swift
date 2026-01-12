//
//  BubbleGroupKey.swift
//  Meomun
//
//  Created by MinwooJe on 1/12/26.
//

/// 메시지 그룹핑 기준
enum BubbleGroupKey: Hashable {
    /// 장소 태그가 있는 메시지들 (같은 좌표의 여러 장소 태그 포함 가능)
    case places(Location)

    /// 장소 태그가 없는 메시지들
    case location(Location)
}
