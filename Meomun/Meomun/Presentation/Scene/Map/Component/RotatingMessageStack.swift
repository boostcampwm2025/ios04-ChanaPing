//
//  RotatingTextStack.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct RotatingMessageStack: View {
    let current: Message
    let next: Message
    let progress: Double

    // 움직일 수 있는 영역 높이 (텍스트 약 2줄 + 날짜)
    private let areaHeight: CGFloat = 44 + 16
    private let movingArea: CGFloat = 16    // 움직일 거리

    var body: some View {
        ZStack(alignment: .center) {
            if progress > 0 {
                messageContent(next)
                    .opacity(progress)
                    .offset(y: (1 - progress) * movingArea)
            }

            messageContent(current)
                .opacity(1 - progress)
                .offset(y: -progress * movingArea)
        }
        .frame(maxHeight: areaHeight, alignment: .center)
        .clipped()
    }
}

private extension RotatingMessageStack {
    @ViewBuilder
    func messageContent(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            BubbleText(text: message.content)

            Text(message.displayDateString)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.gray.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
