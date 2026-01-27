//
//  TimelineSectionHeaderView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import SwiftUI

struct TimelineSectionHeaderView: View {
    let yearMonth: YearMonth

    var body: some View {
        let date = yearMonth.startDate()

        HStack(spacing: 10) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.largeTitle.bold())
                .foregroundStyle(Color.meomunPrimaryColor.opacity(0.75))

            Text(date.formatted(.dateTime.year()))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.meomunPrimaryColor.opacity(0.45))
                .padding(.leading, 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tabActive)
                .opacity(0.75)

            Spacer()

        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.meomunBackgroundColor)
    }
}

#Preview {
    TimelineSectionHeaderView(yearMonth: YearMonth(date: Date.now))
}
