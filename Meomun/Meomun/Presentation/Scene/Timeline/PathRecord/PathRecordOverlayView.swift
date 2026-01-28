//
//  PathRecordOverlayView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/28/26.
//

import SwiftUI
import Foundation

fileprivate enum Constants {
    static let miniMapPadding: CGFloat = 20
    static let miniMapTopPadding: CGFloat = 36

    static let frameInnerBottomPadding: CGFloat = 14
    static let frameHoriziontalPadding: CGFloat = 40
    static let frameVerticalPadding: CGFloat = 160
    static let frameCornerRadius: CGFloat = 3

    static let titlePadding: CGFloat = 14
}

struct PathRecordOverlayView: View {
    private let section: YearMonth
    private let messages: [Message]
    private let onDismiss: () -> Void

    @State private var isPresented = false

    init(
        section: YearMonth,
        messages: [Message],
        onDismiss: @escaping () -> Void = {}
    ) {
        self.section = section
        self.messages = messages
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if isPresented {
                content
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) { isPresented = true }
        }
        .onDisappear { isPresented = false }
    }
}

private extension PathRecordOverlayView {
    var content: some View {
        VStack(spacing: 12) {
            PathRecordMiniMapView(messages: messages)
                .padding(.top, Constants.miniMapTopPadding)
                .padding(.bottom, Constants.miniMapPadding)
                .padding(.horizontal, Constants.miniMapPadding)
                .background(Color.black.opacity(0.02))
            title
        }
        .padding(.bottom, Constants.frameInnerBottomPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Constants.frameCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.frameCornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, Constants.frameHoriziontalPadding)
        .padding(.vertical, Constants.frameVerticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

    }

    var title: some View {
        ZStack {
            Text("\(monthText), 머문 흔적 따라가기")
                .font(.headline.italic())

            HStack {
                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.meomunSecondaryColor)
                        .contentShape(Rectangle())
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(Constants.titlePadding)
    }
}

// MARK: Computed Property
private extension PathRecordOverlayView {
    var monthText: String {
        let date = section.startDate()
        return date.formatted(.dateTime.month(.abbreviated))
    }
}

#Preview {
    let messages: [Message] = [
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-40 * 60),
            content: "벤치에 앉아 잠깐 쉬어요",
            coordinate: .init(latitude: 37.5698, longitude: 126.9775),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-4000 * 60),
            content: "페이드인 되고 있어?",
            coordinate: .init(latitude: 37.5665, longitude: 126.9780),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-100 * 60 * 60),
            content: "따뜻한 커피 향이 지나간다☕️",
            coordinate: .init(latitude: 37.0724, longitude: 126.0746),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-300 * 60 * 60),
            content: "멀리서 버스 브레이크 소리🚍",
            coordinate: .init(latitude: 37.508, longitude: 126.992),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-20000 * 60),
            content: "바닥에 그림자가 길게 늘어져요🌒",
            coordinate: .init(latitude: 36.928, longitude: 126.656),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-1500 * 60),
            content: "누군가 웃는 소리 지나갔다🙂",
            coordinate: .init(latitude: 37.5709, longitude: 125.9786),
            address: "서판교로29",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-100 * 60 * 60),
            content: "새벽 공기가 차갑고 맑다🌙",
            coordinate: .init(latitude: 36.5672, longitude: 126.9708),
            address: "서판교로29",
            placeTag: nil
        )
    ]

    PathRecordOverlayView(section: YearMonth(date: Date.now), messages: messages)
}
