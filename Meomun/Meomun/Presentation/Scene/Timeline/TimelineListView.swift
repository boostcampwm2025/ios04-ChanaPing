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
    @StateObject private var store: TimelineListStore
    private let configuration: Configuration

    init(store: TimelineListStore, configuration: Configuration = .full) {
        _store = StateObject(wrappedValue: store)
        self.configuration = configuration
    }

    var body: some View {
        VStack {
            if configuration.showsHeader { header }

            content
        }
        .background(Color.meomunBackgroundColor)
    }
}

private extension TimelineListView {
    var header: some View {
        ZStack {
            Text(Constants.navigationTitle)
                .font(.headline)
                .foregroundStyle(Color.meomunPrimaryColor)

            HStack {
                Spacer()

                Button {
                    Task {
                        await store.send(intent: .tapEdit)
                    }
                } label: {
                    Text("편집")
                        .font(.headline)
                        .foregroundStyle(Color.meomunPointColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 30)
    }

    var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(store.state.sections, id: \.key) { section in
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

            if configuration.showsFooter { footer }
        }
    }

    var footer: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.meomunSecondaryColor)

            Text("END OF RECORDS")
                .font(.footnote.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.meomunSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }
}

extension TimelineListView {
    struct Configuration: Equatable {
        var showsHeader: Bool
        var showsFooter: Bool
        var showsEditButton: Bool

        static let full = Configuration(showsHeader: true, showsFooter: true, showsEditButton: true)

        static let bottomSheet = Configuration(showsHeader: false, showsFooter: false, showsEditButton: false)
    }
}

#Preview {
    TimelineListView(
        store: TimelineListStore(
            initialMessages: TimelineListStore
                .getTimelineDummyMessages()
        )
    )
}
