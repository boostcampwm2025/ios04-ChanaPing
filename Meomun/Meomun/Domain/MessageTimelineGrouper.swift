//
//  MessageTimelineGrouper.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import Foundation

struct YearMonth: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        return lhs.month < rhs.month
    }
}

extension YearMonth {
    init(date: Date, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.year, .month], from: date)
        self.year = comps.year ?? 0
        self.month = comps.month ?? 0
    }

    func startDate(in calendar: Calendar = .current) -> Date {
        let comps = DateComponents(year: year, month: month, day: 1)
        return calendar.date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }
}

struct MessageTimelineGrouper {
    static func groupByYearMonth(
        _ messages: [Message],
        calendar: Calendar = .current
    ) -> [(key: YearMonth, value: [Message])] {

        let grouped = Dictionary(grouping: messages) { msg in
            YearMonth(date: msg.createdAt, calendar: calendar)
        }

        // 섹션 키 정렬
        let sortedKeys = grouped.keys.sorted(by: >)

        return sortedKeys.map { key in
            let values = (grouped[key] ?? []).sorted { $0.createdAt > $1.createdAt }
            return (key: key, value: values)
        }
    }
}
