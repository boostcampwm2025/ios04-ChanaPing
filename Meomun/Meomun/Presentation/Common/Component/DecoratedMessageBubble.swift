//
//  DecoratedMessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/22/26.
//

import SwiftUI

fileprivate enum Constants {
    // 일반 버블
    static let planeBubbleScale: CGFloat = 1.0
    static let planeBubbleHeightRatio: CGFloat = 1.0
    static let planeBubbleOffset: CGSize = .init(
        width: -15,
        height: 15
    )

    // 공간 버블
    static let placeBubbleScale: CGFloat = 0.8
    static let placeBubbleHeightRatio: CGFloat = 1.0
    static let placeBubbleOffset: CGSize = .init(
        width: 0,
        height: 70
    )
    static let placeBubbleDecoAssetName: String = "placeBubbleBack"
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

    // 다중 메시지만 Decoration 보여주도록
    private var shouldShowDecoration: Bool {
        if case .fixedSize = layout { return true }
        return false
    }

    private var bubbleWidth: CGFloat? {
        if case .fixedSize(let cGFloat) = layout {
            return cGFloat
        }
        return nil
    }

    private var decorationSize: (
        scale: CGFloat,
        heightRatio: CGFloat,
        offset: CGSize
    ) {
        if message.placeTag == nil {
            // 일반 버블
            return (
                scale: Constants.planeBubbleScale,
                heightRatio: Constants.planeBubbleHeightRatio,
                offset: Constants.planeBubbleOffset
            )
        } else {
            // 공간 버블
            return (
                scale: Constants.placeBubbleScale,
                heightRatio: Constants.placeBubbleHeightRatio,
                offset: Constants.placeBubbleOffset
            )
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            decoration

            MessageBubble(
                message: message,
                layout: layout,
                content: content
            )
            .zIndex(1)
        }
        .compositingGroup()
    }
}

extension DecoratedMessageBubble {
    @ViewBuilder
    private var decoration: some View {
        if shouldShowDecoration, let width = bubbleWidth {
            if message.placeTag != nil {
                let config = decorationSize
                let decoWidth = width * config.scale
                let decoHeight = decoWidth * config.heightRatio

                Image(Constants.placeBubbleDecoAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: decoWidth, height: decoHeight)
                    .allowsHitTesting(false)
                    .zIndex(0)
                    .offset(config.offset)
            } else {
                StackBack(bubbleWidth: width)
            }
        }
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
