//
//  CloudDotsLoadingView.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

// MARK: - Models (File scope)

struct SlideSpec: Equatable {
    let widthCentimeters: CGFloat
    let heightCentimeters: CGFloat

    static let standardWidescreen = SlideSpec(widthCentimeters: 33.867, heightCentimeters: 19.05)
}

struct CloudDotSpec: Equatable {
    let xCentimeters: CGFloat
    let yCentimeters: CGFloat
    let widthCentimeters: CGFloat
    let heightCentimeters: CGFloat
}

// MARK: - View

struct CloudDotsLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotionEnabled

    /// nil이면 무한 로딩
    let progress: CGFloat?

    // Appearance
    var dotColor: Color = .white
    var slideSpec: SlideSpec = .standardWidescreen
    var cloudScale: CGFloat = 2.0
    var usesLighterBlendMode: Bool = false

    // Build timing
    var buildProgressSpan: CGFloat = 1.0
    var revealWindow: CGFloat = 0.35
    var baseFillOpacity: CGFloat = 0.10

    // Gooey (=연결감) (main body)
    var maxBlurRadius: CGFloat = 18
    var minBlurRadius: CGFloat = 2
    var alphaThresholdMinimum: CGFloat = 0.45

    // Outer haze (soft colored blur)
    var hazeEnabled: Bool = true
    var hazeColor: Color = .tabActive
    /// 바깥 레이어 투명도 스케일(낮을수록 은은)
    var hazeOpacityScale: CGFloat = 0.18
    /// 본체 blur에 곱해지는 바깥 blur 배수 (클수록 더 멀리 퍼짐)
    var hazeBlurMultiplier: CGFloat = 1.65
    /// 바깥 레이어는 알파 임계치 없이 부드럽게만 번지게
    var hazeUsesAlphaThreshold: Bool = false

    // Indeterminate
    var cycleDurationSeconds: CGFloat = 1.4
    @State private var indeterminatePhase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let containerSize = proxy.size

            let canvasSize = CGSize(
                width: containerSize.width * cloudScale,
                height: containerSize.height * cloudScale
            )

            let canvasOrigin = CGPoint(
                x: (containerSize.width - canvasSize.width) / 2,
                y: (containerSize.height - canvasSize.height) / 2
            )

            let globalProgressValue = currentGlobalProgressValue()
            let easedProgressValue = smoothstep(globalProgressValue)

            Canvas { context, _ in
                // 1) Outer haze layer (different color, blur only)
                if hazeEnabled {
                    context.drawLayer { hazeContext in
                        let mainBlur = blurRadius(for: easedProgressValue)
                        let hazeBlur = max(minBlurRadius, mainBlur * hazeBlurMultiplier)

                        if hazeUsesAlphaThreshold {
                            hazeContext.addFilter(.alphaThreshold(min: alphaThresholdMinimum, color: hazeColor))
                        }

                        hazeContext.addFilter(.blur(radius: hazeBlur))

                        for dotSpec in Constants.dotSpecs {
                            let appearValue = revealAmount(
                                progress: easedProgressValue,
                                delay: 0,
                                revealWindow: revealWindow
                            )

                            let easedAppearValue = smoothstep(appearValue)

                            let dotSize = dotSizeInPoints(dotSpec: dotSpec, canvasSize: canvasSize)
                            let dotCenter = dotCenterInPoints(
                                dotSpec: dotSpec,
                                canvasSize: canvasSize,
                                dotSize: dotSize
                            )

                            // 바깥은 은은하게: baseFillOpacity 영향을 덜 받게
                            let hazeOpacity = clamp01(easedAppearValue) * clamp01(hazeOpacityScale)

                            let dotRect = CGRect(
                                x: canvasOrigin.x + dotCenter.x - dotSize.width / 2,
                                y: canvasOrigin.y + dotCenter.y - dotSize.height / 2,
                                width: dotSize.width,
                                height: dotSize.height
                            )

                            hazeContext.opacity = hazeOpacity
                            hazeContext.fill(Path(ellipseIn: dotRect), with: .color(hazeColor))
                        }
                    }
                }

                // 2) Main body layer (gooey: alphaThreshold + blur)
                context.drawLayer { bodyContext in
                    bodyContext.addFilter(.alphaThreshold(min: alphaThresholdMinimum, color: dotColor))
                    bodyContext.addFilter(.blur(radius: blurRadius(for: easedProgressValue)))

                    for dotSpec in Constants.dotSpecs {
                        let appearValue = revealAmount(
                            progress: easedProgressValue,
                            delay: 0,
                            revealWindow: revealWindow
                        )

                        let easedAppearValue = smoothstep(appearValue)

                        let dotSize = dotSizeInPoints(dotSpec: dotSpec, canvasSize: canvasSize)
                        let dotCenter = dotCenterInPoints(dotSpec: dotSpec, canvasSize: canvasSize, dotSize: dotSize)

                        let opacityValue = baseFillOpacity + (1 - baseFillOpacity) * easedAppearValue

                        let dotRect = CGRect(
                            x: canvasOrigin.x + dotCenter.x - dotSize.width / 2,
                            y: canvasOrigin.y + dotCenter.y - dotSize.height / 2,
                            width: dotSize.width,
                            height: dotSize.height
                        )

                        bodyContext.opacity = opacityValue
                        bodyContext.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                    }
                }
            }
            .blendMode(usesLighterBlendMode ? .screen : .normal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                guard progress == nil else { return }
                guard !reduceMotionEnabled else { return }
                startIndeterminateAnimation()
            }
        }
        .accessibilityLabel("로딩 중")
    }
}

// MARK: - Animation / Progress

private extension CloudDotsLoadingView {
    func startIndeterminateAnimation() {
        indeterminatePhase = 0
        let duration = Double(max(cycleDurationSeconds, Constants.minimumEpsilon))

        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            indeterminatePhase = 1
        }
    }

    func currentGlobalProgressValue() -> CGFloat {
        if let progress {
            let clampedProgress = clamp01(progress)
            let spanValue = max(min(buildProgressSpan, 1), Constants.minimumEpsilon)
            return clamp01(clampedProgress / spanValue)
        }

        return reduceMotionEnabled ? 1 : indeterminatePhase
    }
}

// MARK: - Layout

private extension CloudDotsLoadingView {
    func dotSizeInPoints(dotSpec: CloudDotSpec, canvasSize: CGSize) -> CGSize {
        let normalizedWidth = dotSpec.widthCentimeters / max(slideSpec.widthCentimeters, Constants.minimumEpsilon)
        let normalizedHeight = dotSpec.heightCentimeters / max(slideSpec.heightCentimeters, Constants.minimumEpsilon)

        return CGSize(
            width: canvasSize.width * normalizedWidth,
            height: canvasSize.height * normalizedHeight
        )
    }

    func dotCenterInPoints(dotSpec: CloudDotSpec, canvasSize: CGSize, dotSize: CGSize) -> CGPoint {
        let normalizedXPosition = dotSpec.xCentimeters / max(slideSpec.widthCentimeters, Constants.minimumEpsilon)
        let normalizedYPosition = dotSpec.yCentimeters / max(slideSpec.heightCentimeters, Constants.minimumEpsilon)

        let topLeftXPosition = canvasSize.width * normalizedXPosition
        let topLeftYPosition = canvasSize.height * normalizedYPosition

        return CGPoint(
            x: topLeftXPosition + dotSize.width / 2,
            y: topLeftYPosition + dotSize.height / 2
        )
    }
}

// MARK: - Reveal / Gooey

private extension CloudDotsLoadingView {
    func revealAmount(progress: CGFloat, delay: CGFloat, revealWindow: CGFloat) -> CGFloat {
        let clampedProgress = clamp01(progress)
        let clampedDelay = clamp01(delay)

        let elapsed = clampedProgress - clampedDelay
        if elapsed <= 0 { return 0 }

        let windowValue = max(revealWindow, Constants.minimumEpsilon)
        return clamp01(elapsed / windowValue)
    }

    func blurRadius(for easedProgress: CGFloat) -> CGFloat {
        if reduceMotionEnabled { return minBlurRadius }
        return maxBlurRadius + (minBlurRadius - maxBlurRadius) * easedProgress
    }
}

// MARK: - Utilities

private extension CloudDotsLoadingView {
    func clamp01(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    func smoothstep(_ value: CGFloat) -> CGFloat {
        let time = clamp01(value)
        return (3 * time * time) - (2 * time * time * time)
    }
}

// MARK: - Constants

private enum Constants {
    static let minimumEpsilon: CGFloat = 0.0001

    static let dotSpecs: [CloudDotSpec] = [
        CloudDotSpec(xCentimeters: 16.47, yCentimeters: 7.98, widthCentimeters: 1.84, heightCentimeters: 2.17),
        CloudDotSpec(xCentimeters: 16.28, yCentimeters: 8.84, widthCentimeters: 2.91, heightCentimeters: 1.92),
        CloudDotSpec(xCentimeters: 16.85, yCentimeters: 9.91, widthCentimeters: 1.25, heightCentimeters: 1.16),
        CloudDotSpec(xCentimeters: 16.26, yCentimeters: 10.17, widthCentimeters: 0.89, heightCentimeters: 0.79),
        CloudDotSpec(xCentimeters: 15.76, yCentimeters: 10.16, widthCentimeters: 0.89, heightCentimeters: 0.79),
        CloudDotSpec(xCentimeters: 14.67, yCentimeters: 9.26, widthCentimeters: 1.88, heightCentimeters: 1.60),
        CloudDotSpec(xCentimeters: 15.55, yCentimeters: 8.69, widthCentimeters: 1.41, heightCentimeters: 1.44)
    ]
}
