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
                top: UIColor(red: 0.18, green: 0.11, blue: 0.31, alpha: 1.0),    // 진보라
                bottom: UIColor(red: 0.91, green: 0.63, blue: 0.75, alpha: 1.0) // 분홍
            )

        case .daybreak:
            return (
                top: UIColor(red: 0.96, green: 0.64, blue: 0.73, alpha: 1.0),    // 연분홍
                bottom: UIColor(red: 1.00, green: 0.85, blue: 0.62, alpha: 1.0) // 살구
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
                top: UIColor(red: 0.42, green: 0.20, blue: 0.51, alpha: 1.0),    // 보라
                bottom: UIColor(red: 0.96, green: 0.69, blue: 0.25, alpha: 1.0) // 주황
            )

        case .night:
            return (
                top: UIColor(red: 0.05, green: 0.11, blue: 0.16, alpha: 1.0),    // 거의검정
                bottom: UIColor(red: 0.11, green: 0.16, blue: 0.22, alpha: 1.0) // 진남
            )
        }
    }
}
