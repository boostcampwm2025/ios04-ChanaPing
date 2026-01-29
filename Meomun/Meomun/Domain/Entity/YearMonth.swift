//
//  YearMonth.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
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
