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
    static let textScale: Float = 0.50                          // 텍스트 엔티티 스케일
    static let paddingX: Float = 0.10                           // 텍스트 좌우 여백
    static let paddingY: Float = 0.02                           // 텍스트 상하 여백
    static let minUniform: Float = 0.85                         // 버블 최소 크기 제한
    static let maxUniform: Float = 2.2                          // 버블 최대 크기 제한
    static let textContainerWidth: Float = 0.55                 // 텍스트 최대 넓이
    static let textContainerHeight: Float = 0.18                // 텍스트 최대 높이
    static let statusLineHeight: Float = 0.006                  // 상태 라인 두께
    static let statusLineWidthRatioToBubble: Float = 0.20       // 버블 폭 대비 라인 폭 비율
    static let statusLineTopInsetRatioToBubble: Float = 0.20    // 버블 상단에서 아래로 내릴 비율
    static let entityForwardPadding: Float = 0.01               // 텍스트보다 약간 앞(z+)으로
    static let recentThresholdSeconds: TimeInterval = 20 * 60
}
