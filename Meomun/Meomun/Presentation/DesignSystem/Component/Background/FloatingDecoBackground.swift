//
//  FloatingDecoBackground.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

struct FloatingDecoBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var backgroundImageName: String = "meomunBackLight"
    let bubbleGroupAImageName: String = "meomunDeco1"
    let bubbleGroupBImageName: String = "meomunDeco2"

    var backgroundSpeed: CGFloat = 50
    var bubbleAFloatAmplitude: CGFloat = 10
    var bubbleBFloatAmplitude: CGFloat = 14

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Color.white.ignoresSafeArea()

                ScrollingBackground(
                    backgroundAssetName: backgroundImageName,
                    containerSize: size,
                    scrollSpeedPointsPerSecond: reduceMotion ? 0 : backgroundSpeed,
                    animationTimeSeconds: animationPhase
                )

                floatingGroup(
                    imageName: bubbleGroupAImageName,
                    containerSize: size,
                    time: animationPhase,
                    basePosition: CGPoint(x: size.width * 0.30, y: size.height * 0.28),
                    amplitude: bubbleAFloatAmplitude,
                    period: 5.2,
                    rotationDegrees: 1.8
                )
                .opacity(0.95)

                floatingGroup(
                    imageName: bubbleGroupBImageName,
                    containerSize: size,
                    time: animationPhase + 1.6,
                    basePosition: CGPoint(x: size.width * 0.70, y: size.height * 0.46),
                    amplitude: bubbleBFloatAmplitude,
                    period: 6.6,
                    rotationDegrees: 2.6
                )
                .opacity(0.92)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.06),
                        Color.clear,
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(16))
                    animationPhase += 0.016
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Floating Group

    @ViewBuilder
    private func floatingGroup(
        imageName: String,
        containerSize: CGSize,
        time: CGFloat,
        basePosition: CGPoint,
        amplitude: CGFloat,
        period: CGFloat,
        rotationDegrees: CGFloat
    ) -> some View {
        let motionEnabled = !reduceMotion

        let y = motionEnabled ? (amplitude * sine(time, period: period)) : 0
        let x = motionEnabled ? ((amplitude * 0.55) * cosine(time, period: period * 1.2)) : 0
        let rot = motionEnabled ? (rotationDegrees * sine(time, period: period * 0.9)) : 0
        let scale = motionEnabled ? (1.0 + 0.01 * sine(time, period: period * 1.1)) : 1.0

        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: containerSize.width * 0.62)
            .position(x: basePosition.x + x, y: basePosition.y + y)
            .rotationEffect(.degrees(Double(rot)))
            .scaleEffect(scale)
            .allowsHitTesting(false)
    }

    private func sine(_ time: CGFloat, period: CGFloat) -> CGFloat {
        let omega = (2 * CGFloat.pi) / max(period, 0.001)
        return CGFloat(Darwin.sin(Double(time * omega)))
    }

    private func cosine(_ time: CGFloat, period: CGFloat) -> CGFloat {
        let omega = (2 * CGFloat.pi) / max(period, 0.001)
        return CGFloat(Darwin.cos(Double(time * omega)))
    }
}
