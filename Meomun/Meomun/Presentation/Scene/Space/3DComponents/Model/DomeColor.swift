//
//  DomeColor.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import UIKit.UIColor

/// DayPart(시간대)에 따른 돔의 GradientPair를 정의하는 모델입니다.
enum DomeColor {
    typealias GradientPair = (top: UIColor, bottom: UIColor)

    static func colors(for dayPart: DayPart) -> GradientPair {
        switch dayPart {

        case .dawn:
            return (
                top: UIColor(red: 0.16, green: 0.14, blue: 0.28, alpha: 1.0),    // 잔잔한 남보라
                bottom: UIColor(red: 0.42, green: 0.36, blue: 0.52, alpha: 1.0) // 흐린 라일락
            )

        case .daybreak:
            return (
                top: UIColor(red: 0.55, green: 0.42, blue: 0.50, alpha: 1.0),    // 차분한 로즈
                bottom: UIColor(red: 0.80, green: 0.68, blue: 0.64, alpha: 1.0) // 미묘한 살구 베이지
            )

        case .morning:
            return (
                top: UIColor(red: 0.66, green: 0.85, blue: 0.94, alpha: 1.0),    // 연하늘
                bottom: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0) // 흰
            )

        case .afternoon:
            return (
                top: UIColor(red: 0.36, green: 0.68, blue: 0.89, alpha: 1.0),    // 하늘
                bottom: UIColor(red: 0.68, green: 0.84, blue: 0.95, alpha: 1.0) // 연하늘
            )

        case .evening:
            return (
                top: UIColor(red: 0.48, green: 0.41, blue: 0.44, alpha: 1.0),    // 따뜻한 로지 그레이 공기
                bottom: UIColor(red: 0.90, green: 0.74, blue: 0.58, alpha: 1.0) // 밝은 노을 잔광
            )

        case .night:
            return (
                top: UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1.0),    // 딥 네이비
                bottom: UIColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1.0) // 숨 쉬는 어둠
            )
        }
    }
}
