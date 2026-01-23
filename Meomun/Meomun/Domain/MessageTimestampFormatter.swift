//
//  MessageTimestampFormatter.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import Foundation

struct MessageTimestampFormatter {
    static func string(from date: Date) -> String {
        let now = Date()
        let elapsed = now.timeIntervalSince(date)
        let oneDay: TimeInterval = 60 * 60 * 24

        if elapsed < oneDay {
            return relativeString(from: date, now: now)
        } else {
            return absoluteString(from: date)
        }
    }

    static func relativeString(from date: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func absoluteString(from date: Date) -> String {
        return date.formatted(.dateTime.locale(Locale.current)
        )
    }
}
