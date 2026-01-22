//
//  MessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/7/26.
//

import SwiftUI

enum BubbleLayout {
    case flexible      // 단일 메시지
    case fixedSize(CGFloat)    // 회전 메시지
}

struct MessageBubble<Content: View>: View {
    let message: Message
    let layout: BubbleLayout
    let content: (Message) -> Content

    var maxWidth: CGFloat = 210

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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            locationPart

            bodyPart

            datePart
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .applyLayout(
            layout,
            maxWidth: maxWidth
        )
        .background(bubbleBackground)
        .overlay(alignment: .bottomLeading) {
            dividerOverlay
        }
    }
}

private extension MessageBubble {
    @ViewBuilder
    var locationPart: some View {
        if let locationName = message.displayLocationName {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#53808C"))

                Text(locationName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray.opacity(0.8))
            }
        }
    }

    @ViewBuilder
    var bodyPart: some View {
        let bodyView = content(message)

        if case .fixedSize = layout {
            bodyView
                .frame(height: 36, alignment: .center)
                .clipped()
        } else {
            bodyView
        }
    }

    var datePart: some View {
        Text(message.displayDateString)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.gray.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 5)
    }

    var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.06),
                    radius: 12,
                    x: 0,
                    y: 6)
    }

    var dividerOverlay: some View {
        Rectangle()
            .fill(Color.black.opacity(0.8))
            .frame(height: 1 / UIScreen.main.scale)
            .padding(.horizontal, 12)
            .padding(.bottom, 29)
    }
}

struct BubbleText: View {
    let text: String
    var maxWidth: CGFloat? = 180

    var body: some View {
        // 본문 (최대 2줄)
        Text(text)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.black.opacity(0.9))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(
                idealWidth: nil,
                maxWidth: maxWidth,
                alignment: .leading
            )
            .clampMaxHeight(56)
    }
}

// MARK: - layout 전용 모디파이어

private extension View {
    @ViewBuilder
    func applyLayout(_ layout: BubbleLayout, maxWidth: CGFloat) -> some View {
        Group {
            switch layout {
            case .flexible:
                self
                    .frame(
                        maxWidth: maxWidth,
                        alignment: .leading
                    )
                    .fixedSize(horizontal: true, vertical: false)

            case .fixedSize(let fixedSize):
                self
                    .frame(
                        width: fixedSize,
                        height: 103,
                        alignment: .leading
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let placeMessage = Message(
        id: MessageID(value: UUID()),
        createdAt: Date(),
        content: "[한줄] 오늘 좀 춥다🫥🍃",
        coordinate: .init(latitude: 0, longitude: 0),
        address: nil,
        placeTag: Place(
            id: PlaceID(value: ""),
            name: "장소 이름",
            coordinate: .init(
                latitude: 0,
                longitude: 0
            )
        )
    )

    let longMessage = Message(
        id: MessageID(value: UUID()),
        createdAt: Date(),
        content: "[두줄] 오늘 좀 asfrfrfasxscscscs춥다🫥🍃",
        coordinate: .init(latitude: 0, longitude: 0),
        address: nil,
        placeTag: Place(
            id: PlaceID(value: ""),
            name: "장소 이름",
            coordinate: .init(
                latitude: 0,
                longitude: 0
            )
        )
    )

    let longMessage2 = Message(
        id: MessageID(value: UUID()),
        createdAt: Date(),
        content: "sdcfvvfvfvffvfvfvfvfvfvfvfvfff",
        coordinate: .init(latitude: 0, longitude: 0),
        address: nil,
        placeTag: Place(
            id: PlaceID(value: ""),
            name: "장소 이름",
            coordinate: .init(
                latitude: 0,
                longitude: 0
            )
        )
    )

    let noPlaceMessage = Message(
        id: MessageID(value: UUID()),
        createdAt: Date(),
        content: "dkfdkkdlsjkd",
        coordinate: .init(latitude: 0, longitude: 0),
        address: "어딘가의 주소",
        placeTag: nil
    )

    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()

        VStack(alignment: .leading, spacing: 12) {
            Text(".flexible (단일 버블)")

            MessageBubble(
                message: placeMessage,
                layout: .flexible
            )

            MessageBubble(
                message: longMessage,
                layout: .flexible
            )

            MessageBubble(
                message: longMessage2,
                layout: .flexible
            )

            Text(".fixedSize(170) (회전 버블)")

            MessageBubble(
                message: placeMessage,
                layout: .fixedSize(170)
            )

            MessageBubble(
                message: noPlaceMessage,
                layout: .fixedSize(170)
            )
        }
    }
}
