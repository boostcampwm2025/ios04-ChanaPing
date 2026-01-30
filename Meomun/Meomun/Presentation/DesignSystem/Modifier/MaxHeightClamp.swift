//
//  MaxHeightClamp.swift
//  Meomun
//
//  Created by 지연 on 1/22/26.
//

import SwiftUI

/// 1. HeightKey: 뷰의 실제 높이 측정
/// 2. MaxHeightClamp: 측정한 실제 높이와 maxHeight 중 더 작은 값으로 최종 높이를 강제로 결정

struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MaxHeightClamp: ViewModifier {
    let maxHeight: CGFloat                      // 최대 허용 높이
    @State private var measured: CGFloat = 0    // 실제 측정된 콘텐츠 높이

    func body(content: Content) -> some View {
        content
            .background(
                // GeometryReader: 자신이 차지한 실제 레이아웃 크기를 알려줌.
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: HeightKey.self,
                            value: proxy.size.height
                        )
                }
            )
            // 높이 바뀔 때마다 호출 -> 다시 계산
            .onPreferenceChange(HeightKey.self) { height in
                let rounded = (height * 2).rounded() / 2
                if abs(rounded - measured) > 0.5 {
                    measured = rounded
                } else if measured == 0 {
                    measured = rounded
                }
            }
            // 측정 높이와 maxHeight 비교 -> 더 작은 값으로 높이 고정
            .frame(height: min(measured == 0 ? maxHeight : measured, maxHeight))
    }
}

// MARK: - View 확장 모디파이어

extension View {
    func clampMaxHeight(_ maxHeight: CGFloat) -> some View {
        modifier(MaxHeightClamp(maxHeight: maxHeight))
    }
}
