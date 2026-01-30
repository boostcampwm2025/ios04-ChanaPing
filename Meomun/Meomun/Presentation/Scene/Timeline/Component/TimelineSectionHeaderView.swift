//
//  TimelineSectionHeaderView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import SwiftUI

struct TimelineSectionHeaderView: View {
    let yearMonth: YearMonth
    let onTapButton: () -> Void

    var body: some View {
        let date = yearMonth.startDate()

        HStack(spacing: 10) {
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.largeTitle.bold())
                .foregroundStyle(Color.mmTextBrand.opacity(0.75))

            Text(date.formatted(.dateTime.year()))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.mmTextBrand.opacity(0.45))
                .padding(.leading, 6)

            Spacer()

            Button(action: onTapButton) {
                HStack(spacing: 6) {
                    Text("흔적 따라가기")
                        .font(.footnote.weight(.semibold))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(Color.tabActive)
                .opacity(0.75)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.mmBackground)
    }
}

#Preview {
    TimelineSectionHeaderView(yearMonth: YearMonth(date: Date.now), onTapButton: {})
}
