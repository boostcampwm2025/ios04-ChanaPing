//
//  RotatingTextStack.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct RotatingTextStack: View {
    let currentText: String
    let nextText: String
    let progress: Double

    // 텍스트가 움직일 수 있는 영역 높이 (약 2줄)
    private let textAreaHeight: CGFloat = 44
    private let movingArea: CGFloat = 16    // 움직일 거리

    var body: some View {
        ZStack(alignment: .topLeading) {
            if progress > 0 {
                BubbleText(text: nextText)
                    .opacity(progress)
                    .offset(y: (1 - progress) * movingArea)
            }

            BubbleText(text: currentText)
                .opacity(1 - progress)
                .offset(y: -progress * movingArea)
        }
        .frame(maxHeight: textAreaHeight, alignment: .top)
        .clipped()
    }
}
