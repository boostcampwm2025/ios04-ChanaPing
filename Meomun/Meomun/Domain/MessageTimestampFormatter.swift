//
//  MessageTimestampFormatter.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import Foundation

enum MessageTimestampFormatterStyle {
    case date
    case dateTime
}

struct MessageTimestampFormatter {
    let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func string(from date: Date, style: MessageTimestampFormatterStyle, now: Date = Date()) -> String {
        let elapsed = now.timeIntervalSince(date)
        let oneDay: TimeInterval = 60 * 60 * 24

        if elapsed < oneDay {
            return relativeString(from: date, now: now)
        } else {
            return absoluteString(from: date, style: style)
        }
    }

    private func relativeString(from date: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = locale

        return formatter.localizedString(for: date, relativeTo: now)
    }

    private func absoluteString(from date: Date, style: MessageTimestampFormatterStyle) -> String {
        switch style {
        case .date:
            return date.formatted(.dateTime.year().month().day().locale(locale))

        case .dateTime:
            return date.formatted(date: .complete, time: .shortened)
        }
    }
}
