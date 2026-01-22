//
//  MessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/7/26.
//

import SwiftUI

enum MessageStatusIndicator {
    case none
    case recent
    case normal
}

enum BubbleLayout {
    case flexible      // 단일 메시지
    case fixedSize(CGFloat)    // 회전 메시지
}

struct MessageBubble<Content: View>: View {
    let placeName: String?
    let createdAt: Date?
    let statusIndicator: MessageStatusIndicator
    let layout: BubbleLayout
    let content: Content

    var maxWidth: CGFloat = 210

    init(
        placeName: String?,
        createdAt: Date = .init(timeIntervalSince1970: 0),
        statusIndicator: MessageStatusIndicator,
        layout: BubbleLayout,
        @ViewBuilder content: () -> Content
    ) {
        self.placeName = placeName
        self.createdAt = createdAt
        self.statusIndicator = statusIndicator
        self.layout = layout
        self.content = content()
    }

    private var statusIndicatorColor: Color {
        switch statusIndicator {
        case .none:
            return .clear
        case .recent:
            return .orange
        case .normal:
            return .blue
        }
    }

    var body: some View {
        //        HStack(alignment: .top, spacing: 10) {
        // 왼쪽 세로 라인
        //            Capsule()
        //                .fill(statusIndicatorColor)
        //                .frame(width: 3)
        //                .padding(.vertical, 11)

        VStack(alignment: .leading, spacing: 6) {
            // 장소 태그 (옵셔널)
            if let placeName, !placeName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#53808C"))

                    Text(placeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gray.opacity(0.8))
                }
            }

            if case .fixedSize = layout {
                content
                    .frame(height: 36, alignment: .center)
                    .clipped()
            } else {
                content
            }

            Text("25.02.01")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.gray.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 15)
        .applyLayout(
            layout,
            maxWidth: maxWidth,
            background: bubbleBackground
        )
    }

//        )
//    }
}

private extension MessageBubble {
    var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.06),
                    radius: 12,
                    x: 0,
                    y: 6)
    }
}

struct BubbleText: View {
    let text: String
    var maxWidth: CGFloat? = 190

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
            .clampMaxHeight(50)
    }
}

// MARK: - layout 전용 모디파이어

private extension View {
    @ViewBuilder
    func applyLayout(_ layout: BubbleLayout, maxWidth: CGFloat, background: some View) -> some View {
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
                        height: 98,
                        alignment: .leading
                    )
            }
        }
        .background(background)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()

        VStack(alignment: .leading, spacing: 12) {
            Text(".flexible (단일 버블)")
            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .flexible
            ) {
                BubbleText(text: "[한줄] 오늘 좀 춥다🫥🍃")
            }

            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .flexible
            ) {
                BubbleText(text: "[두줄] 오늘 좀 asfrfrfasxscscscs춥다🫥🍃")
            }

            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .flexible
            ) {
                BubbleText(text: "[두줄] 이건 30자 메시지에요 재밌죠 나는 자고싶어요")
            }

            Text(".fixedSize(170) (회전 버블)")
            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .fixedSize(170)
            ) {
                BubbleText(text: "🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥")
            }

            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .fixedSize(170)
            ) {
                BubbleText(text: "dkfdkkdkdksdjkfskdlsjkd")
            }

            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .fixedSize(170)
            ) {
                BubbleText(text: "dkfdkkdlsjkd")
            }
        }
    }
}
