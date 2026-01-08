//
//  MessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/7/26.
//

import SwiftUI

/// 1) 버블 내부 텍스트 rotate 기능 지원 X 시
///     - placeName 있을 수도 / 없을 수도
///     - 좌측 라인 visible
/// 2) 버블 내부 텍스트 rotate 기능 지원 O 시
///     - placeName 항상 있음
///     - 좌측 라인 invisible

enum MessageStatusIndicator {
    case none
    case recent
    case normal
}

enum BubbleLayout {
    case flexible      // 단일 메시지
    case fixedWidth(CGFloat)    // 회전 메시지
}

struct MessageBubble<Content: View>: View {
    let placeName: String?
    let statusIndicator: MessageStatusIndicator
    let layout: BubbleLayout
    let content: Content

    var maxWidth: CGFloat = 210

    init(
        placeName: String?,
        statusIndicator: MessageStatusIndicator,
        layout: BubbleLayout,
        @ViewBuilder content: () -> Content
    ) {
        self.placeName = placeName
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
        HStack(alignment: .top, spacing: 10) {
            // 왼쪽 세로 라인
            Capsule()
                .fill(statusIndicatorColor)
                .frame(width: 3)
                .padding(.vertical, 11)

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

                content
            }
            .padding(.vertical, 13)
            .padding(.trailing, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06),
                        radius: 12,
                        x: 0,
                        y: 6)
        )
        .applyLayout(layout, maxWidth: maxWidth)
    }
}

struct BubbleText: View {
    let text: String

    var body: some View {
        // 본문 (최대 2줄)
        Text(text)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.black.opacity(0.9))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - layout 전용 모디파이어

private extension View {
    @ViewBuilder
    func applyLayout(_ layout: BubbleLayout, maxWidth: CGFloat) -> some View {
        switch layout {
        case .flexible:
            self
                .frame(maxWidth: maxWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

        case .fixedWidth(let fixedSize):
            self
                .frame(width: fixedSize, height: 82, alignment: .leading)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()

        VStack(alignment: .leading, spacing: 24) {
            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .normal,
                layout: .flexible
            ) {
                BubbleText(text: "오늘 좀 춥다🫥🍃")
            }

            MessageBubble(
                placeName: "장소 이름",
                statusIndicator: .none,
                layout: .fixedWidth(170)
            ) {
                BubbleText(text: "🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥")
            }

            MessageBubble(
                placeName: nil,
                statusIndicator: .recent,
                layout: .flexible
            ) {
                BubbleText(text: "최근에 남긴 따끈따끈한 메시지라서 주황색 라인으로 표시")
            }
        }
    }
}
