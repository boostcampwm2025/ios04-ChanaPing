//
//  MessageBoxView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/22/26.
//

import SwiftUI

private enum Layout {
    static let cornerRadius: CGFloat = 12

    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 20

    static let metaChipPaddingH: CGFloat = 12
    static let metaChipPaddingV: CGFloat = 6

    static let minWidth: CGFloat = 100
    static let minHeight: CGFloat = 100
}

struct MessageBoxView: View {
    private let message: Message
    private let onDelete: (() -> Void)

    init(message: Message, onDelete: @escaping (() -> Void)) {
        self.message = message
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            messageTextView

            VStack(alignment: .leading, spacing: 10) {
                addressView

                Divider()

                metaRowView
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .frame(minWidth: Layout.minWidth, alignment: .leading)
        .frame(minHeight: Layout.minHeight, alignment: .topLeading)
        .background(backgroundView)
    }
}

private extension MessageBoxView {
    var messageTextView: some View {
        Text(message.content)
            .font(.body)
            .foregroundStyle(Color.mmTextBrand.opacity(0.8))
            .frame(maxHeight: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    var addressView: some View {
        HStack(alignment: .center) {
            Image(systemName: "mappin.and.ellipse")
            Text(message.placeTag?.name ?? message.address)
        }
        .font(.footnote.bold())
        .foregroundStyle(Color.mmSecondary)
    }

    var metaRowView: some View {
        HStack {
            Text(message.displayDateTimeString)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.mmSecondary)

            Spacer()

            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                VStack(alignment: .trailing) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.mmSecondary)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    var backgroundView: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            .fill(Color.mmContainerBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .strokeBorder(Color.mmPrimary.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 2)
            .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
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
            address: "가람로 109가람로 109가람로 109가람로 109가람로 109가람로 109가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-15000 * 60),
            content: "12345678901234567890123456789012",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        )
    ]

    VStack(spacing: 10) {
        ForEach(messages) { message in
            MessageBoxView(message: message, onDelete: { })
        }
    }
}
