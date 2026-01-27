//
//  TimelineRowView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import SwiftUI

struct TimelineRowView: View {
    let message: Message
    let showTopLine: Bool
    let showBottomLine: Bool
    private let selectionState: TimelineSelectionState

    init(
        message: Message,
        showTopLine: Bool,
        showBottomLine: Bool,
        selectionState: TimelineSelectionState
    ) {
        self.message = message
        self.showTopLine = showTopLine
        self.showBottomLine = showBottomLine
        self.selectionState = selectionState
    }

    @State private var messageBoxHeight: CGFloat = 0

    private var indicatorHeight: CGFloat {
        max(messageBoxHeight * 1.3, 120)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            TimelineIndicatorView(
                height: indicatorHeight,
                showTopLine: showTopLine,
                showBottomLine: showBottomLine,
                selectionState: selectionState
            )

            MessageBoxView(message: message)
                .readHeight { newHeight in
                    if newHeight > 0, abs(newHeight - messageBoxHeight) > 0.5 {
                        messageBoxHeight = newHeight
                    }
                }
        }
        .padding(.horizontal, 14)
    }
}

#Preview {
    var selectionStates: [TimelineSelectionState]  = [.inactive, .unselected, .selected]
    let messages: [Message] =  [
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-7 * 60),
            content: "[Case4] NoPlace 스택 메시지 1",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-30 * 60),
            content: "[Case4] NoPlace 스택 메시지 2",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-15000 * 60),
            content: "[Case4] NoPlace 스택 메시지 3",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        )
    ]

    ScrollView {
        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
            TimelineRowView(
                message: message,
                showTopLine: index != 0,
                showBottomLine: index != messages.count - 1,
                selectionState: selectionStates[index % messages.count]
            )
        }
    }
}
