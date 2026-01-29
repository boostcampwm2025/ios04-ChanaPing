//
//  MessageTimelineGrouper.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import Foundation

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
