//
//  MainMapViewController.swift
//  Fleeting-Prototype
//
//  Created by MinwooJe on 12/18/25.
//

import SwiftUI
import UIKit

import NMapsMap

final class BubbleConfiguration {
    let marker: NMFMarker
    let messages: [String]
    var currentIndex: Int
    var lastRotationTime: TimeInterval
    var animationStartTime: TimeInterval?
    var animationProgress: Double
    var isAnimating: Bool
    var currentText: String
    var nextText: String

    init(
        marker: NMFMarker,
        messages: [String],
        currentIndex: Int,
        lastRotationTime: TimeInterval,
        animationStartTime: TimeInterval? = nil,
        animationProgress: Double,
        isAnimating: Bool,
        currentText: String,
        nextText: String
    ) {
        self.marker = marker
        self.messages = messages
        self.currentIndex = currentIndex
        self.lastRotationTime = lastRotationTime
        self.animationStartTime = animationStartTime
        self.animationProgress = animationProgress
        self.isAnimating = isAnimating
        self.currentText = currentText
        self.nextText = nextText
    }
}

struct AnimatedBubbleStack: View {
    let currentText: String
    let nextText: String
    let animationProgress: Double // 0.0 ~ 1.0

    var body: some View {
        ZStack {
            // 다음 메시지 (아래에서 위로 나타남)
            if animationProgress > 0 {
                Text(nextText)
                    .opacity(animationProgress)
                    .offset(y: (1 - animationProgress) * 30)
            }

            // 현재 메시지 (위로 사라짐)
            Text(currentText)
                .opacity(1 - animationProgress)
                .offset(y: -animationProgress * 30)
        }
        .shadow(radius: 6, y: 2)
        .padding()
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

final class MainMapViewController: UIViewController {

}
