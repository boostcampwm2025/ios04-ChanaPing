//
//  TimelineListView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "머물렀던 순간들"
}

struct TimelineListView: View {
    let messages: [Message]

    private var sections: [(key: YearMonth, value: [Message])] {
        MessageTimelineGrouper.groupByYearMonth(messages)
    }

    var body: some View {
        VStack {
            header

            content
        }
        .background(Color.meomunBackgroundColor)
        .toolbar { toolbarContent }
    }
}

private extension TimelineListView {
    var header: some View {
        VStack(spacing: 0) {
            Text(Constants.navigationTitle)
                .font(.headline)
                .foregroundStyle(Color.meomunPrimaryColor)
                .padding(.top, 18)
                .padding(.bottom, 30)
        }
    }

    var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6, pinnedViews: [.sectionHeaders]) {
                ForEach(sections, id: \.key) { section in
                    Section {
                        let monthMessages = section.value

                        ForEach(Array(monthMessages.enumerated()), id: \.element.id) { index, message in
                            TimelineRowView(
                                message: message,
                                showTopLine: index != 0,
                                showBottomLine: index != monthMessages.count - 1
                            )
                        }
                    } header: {
                        TimelineSectionHeaderView(yearMonth: section.key)
                    }
                }
            }
            .padding(.bottom, 16)

            footer
        }
    }

    var footer: some View {
        VStack(spacing: 10) {
            if #available(iOS 26.0, *) {
                Image(systemName: "book.pages")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color.meomunSecondaryColor)
                    .symbolEffect(.drawOn.individually, options: .nonRepeating)
            } else {
                Image(systemName: "book.pages")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color.meomunSecondaryColor)
            }

            Text("END OF RECORDS")
                .font(.footnote.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.meomunSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(Constants.navigationTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.meomunPrimaryColor)
        }
    }
}
#Preview {
    TimelineListView(messages: TimelineListView.getTimelineDummyMessages())
}
