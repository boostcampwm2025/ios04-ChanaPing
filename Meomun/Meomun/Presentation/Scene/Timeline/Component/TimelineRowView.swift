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

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TimelineIndicatorView(
                showTopLine: showTopLine,
                showBottomLine: showBottomLine
            )

            MessageBoxView(message: message)
        }
        .padding(.horizontal, 14)
    }
}

#Preview {
    var messages: [Message] =  [
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-7 * 60),
            content: "[Case4] NoPlace 스택 메시지 1",
            coordinate: Coordinate.defaultCoordinate,
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-30 * 60),
            content: "[Case4] NoPlace 스택 메시지 2",
            coordinate: Coordinate.defaultCoordinate,
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-15000 * 60),
            content: "[Case4] NoPlace 스택 메시지 3",
            coordinate: Coordinate.defaultCoordinate,
            placeTag: nil
        )
    ]

    ScrollView {
        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
            TimelineRowView(
                message: message,
                showTopLine: index != 0,
                showBottomLine: index != messages.count - 1
            )
        }
    }
}
