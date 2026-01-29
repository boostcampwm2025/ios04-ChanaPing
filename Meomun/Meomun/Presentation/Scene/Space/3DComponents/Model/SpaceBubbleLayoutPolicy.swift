//
//  SpaceBubbleLayoutPolicy.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import Foundation

/// 공간 메시지 버블 UI/레이아웃 정책(Policy) & 렌더링 파라미터(Parameters)를 정의하는 모델입니다.
enum SpaceBubbleLayoutPolicy {
    static let baseBubbleScale: Float = 0.10                    // 버블 스케일 표준
    static let contentTextScale: Float = 0.4                   // 텍스트 엔티티 스케일
    static let dateTextScale: Float = 0.25

    static let paddingX: Float = 0.10                           // 텍스트 좌우 여백
    static let paddingY: Float = 0.02                           // 텍스트 상하 여백

    static let minUniform: Float = 0.85                         // 버블 최소 크기 제한
    static let maxUniform: Float = 2.2                          // 버블 최대 크기 제한

    static let textContainerWidth: Float = 0.55                 // 텍스트 최대 넓이
    static let textContainerHeight: Float = 0.18                // 텍스트 최대 높이

    static let entityForwardPadding: Float = 0.01               // 텍스트보다 약간 앞(z+)으로
    static let recentThresholdSeconds: TimeInterval = 20 * 60

    static let textAlignY: Float = 0.04
}
