//
//  DayPart.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import Foundation

enum DayPart {
    /// 0-5 시
    case dawn

    /// 5-7 시
    case daybreak

    /// 7-12 시
    case morning

    /// 12-17 시
    case afternoon

    /// 17-21 시
    case evening

    /// 21-24 시
    case night
}

extension DayPart {
    /// Date → hour 추출 후 from(hour:)를 사용해 DayPart를 계산합니다.
    static func current(date: Date = Date(), calendar: Calendar = .current) -> DayPart {
        let hour = calendar.component(.hour, from: date) // 0...23
        return from(hour: hour)
    }

    /// 현재 시각(Date)을 기준으로 DayPart를 계산합니다.
    ///
    /// 경계는 다음과 같이 "앞은 포함, 뒤는 미포함"(half-open)으로 처리합니다.
    /// - dawn:     [0, 5)
    /// - daybreak: [5, 7)
    /// - morning:  [7, 12)
    /// - afternoon:[12, 17)
    /// - evening:  [17, 21)
    /// - night:    [21, 24)
    private static func from(hour: Int) -> DayPart {
        switch hour {
        case 0..<5:
            return .dawn
        case 5..<7:
            return .daybreak
        case 7..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        case 21..<24:
            return .night
        default:
            // 도메인 안전장치: hour는 원칙적으로 0...23 이어야 함
            assertionFailure("Invalid hour: \(hour). Expected 0...23.")
            return .night
        }
    }
}
