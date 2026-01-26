//
//  DecoratedMessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/22/26.
//

import SwiftUI

fileprivate enum Constants {
    static let placeIconSize: CGFloat = 30
    static let placeIconOffsetY: CGFloat = -20
}

struct DecoratedMessageBubble<Content: View>: View {
    let message: Message
    let layout: BubbleLayout
    let content: (Message) -> Content

    init(
        message: Message,
        layout: BubbleLayout,
        @ViewBuilder content: @escaping (Message) -> Content = {
            BubbleText(
                text: $0.content
            )
        }
    ) {
        self.message = message
        self.layout = layout
        self.content = content
    }

    // 다중 메시지 여부
    private var isMultiBubble: Bool {
        if case .fixedSize = layout { return true }
        return false
    }

    // 장소 태그 존재 여부
    private var hasPlaceTag: Bool {
        if message.placeTag != nil { return true }
        return false
    }

    private var bubbleWidth: CGFloat? {
        if case .fixedSize(let cGFloat) = layout {
            return cGFloat
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .center) {
            if !hasPlaceTag, isMultiBubble, let width = bubbleWidth {
                StackBack(bubbleWidth: width)
            }

            MessageBubble(
                message: message,
                layout: layout,
                content: content
            )
            .zIndex(1)
            .overlay(alignment: .top) {
                if hasPlaceTag {
                    placeIcon
                        .offset(y: Constants.placeIconOffsetY)
                }
            }
        }
        .compositingGroup()
    }
}

private extension DecoratedMessageBubble {
    var placeIcon: some View {
        Image("spaceIcon")
            .resizable()
            .scaledToFit()
            .frame(width: Constants.placeIconSize, height: Constants.placeIconSize)
            .padding(1)
            .background(
                Circle()
                    .fill(Color.white)
                    .offset(y: 3)
                    .clipped(antialiased: true)
            )
            .zIndex(2)
    }
}

#Preview {
    DecoratedMessageBubble(
        message: .init(
            id: MessageID(value: UUID()),
            createdAt: Date.now,
            content: "test decoration",
            coordinate: Coordinate.seoulCity,
            address: "adresse test",
            placeTag: .init(
                id: PlaceID(value: "id"),
                name: "place test",
                coordinate: .init(
                    latitude: 0,
                    longitude: 0
                )
            )
        ),
        layout: .fixedSize(180)
    ) { _ in
        BubbleText(text: "test")
    }
    .padding(50)

    DecoratedMessageBubble(
        message: .init(
            id: MessageID(value: UUID()),
            createdAt: Date.now,
            content: "test decoration",
            coordinate: Coordinate.seoulCity,
            address: "adresse test",
            placeTag: nil
        ),
        layout: .fixedSize(180)
    ) { _ in
        BubbleText(text: "test")
    }
}
