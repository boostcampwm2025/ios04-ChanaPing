//
//  RotatingMessageBubbleStack.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct RotatingMessageBubbleStack: View {
    let current: Message
    let next: Message
    let progress: Double

    var body: some View {
        ZStack {
            if progress > 0 {
                MessageBubble(
                    text: next.content,
                    placeName: next.placeTag?.name,
                    isRecent: next.isRecent(),
                    showsAccentLine: false
                )
                .opacity(progress)
                .offset(y: (1 - progress) * 30)
            }

            MessageBubble(
                text: current.content,
                placeName: current.placeTag?.name,
                isRecent: current.isRecent(),
                showsAccentLine: false
            )
            .opacity(1 - progress)
            .offset(y: -progress * 30)
        }
    }
}
