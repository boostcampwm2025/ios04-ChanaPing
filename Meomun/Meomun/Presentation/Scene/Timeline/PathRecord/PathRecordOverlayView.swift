//
//  PathRecordOverlayView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/28/26.
//

import SwiftUI
import Foundation

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
                VStack {
                    header
                    content
                }
                .padding(28)
                .frame(width: 320, height: 400)
                .background(Color.white)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .onTapGesture { }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = true
            }
        }
        .onDisappear { isPresented = false }
    }
}

private extension PathRecordOverlayView {
    var header: some View {
        ZStack {
            Text("\(monthText), 머문 흔적 따라가기")
                .font(.headline)
                .padding(.bottom, 8)

            HStack {
                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.meomunSecondaryColor)
                        .padding(10)
                        .contentShape(Rectangle())
                }
            }
        }
    }
    var content: some View {
        let calendar = Calendar.current

        return ScrollView {
            VStack {
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.content)
                            .font(.footnote)

                        Text("위도: \(message.coordinate.latitude)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("경도: \(message.coordinate.longitude)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        let day = calendar.component(.day, from: message.createdAt)
                        Text("일자: \(day.description)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    Divider()
                }
            }
        }
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

    PathRecordOverlayView(section: YearMonth(date: Date.now), messages: messages)
}
