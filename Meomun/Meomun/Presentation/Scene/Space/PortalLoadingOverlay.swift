import SwiftUI

struct PortalLoadingOverlay: View {
    let title: String
    let isReady: Bool
    let onFinished: () -> Void

    @State private var ringRotation: Double = 0
    @State private var pulse: Bool = false

    @State private var preZoom: Bool = false
    @State private var coverStage: Int = 0
    @State private var fadeOut: Bool = false
    @State private var softenMotion: Bool = false
    @State private var didRunFinish: Bool = false

    @State private var coreFade: Double = 1.0

    var body: some View {
        ZStack {
            FloatingDecoBackground(
                backgroundImageName: "meomunBackDark",
                backgroundSpeed: 22
            )
            .opacity(fadeOut ? 0.0 : 0.35)
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.75), value: fadeOut)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let base: CGFloat = size * 0.30

                let stageMultiplier: CGFloat = {
                    switch coverStage {
                    case 1: return 1.6
                    case 2: return 2.4
                    default: return 1.0
                    }
                }()

                let portalSize: CGFloat = base * stageMultiplier

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.40),
                                    Color.white.opacity(0.58)
                                ],
                                center: .center,
                                startRadius: 6,
                                endRadius: base * 0.85
                            )
                        )
                        .opacity(coreFade)
                        .animation(.easeOut(duration: 0.55), value: coreFade)
                        .overlay(
                            Circle()
                                .fill(Color.mmSecondary.opacity(0.08))
                                .blur(radius: 14)
                                .scaleEffect(softenMotion ? 1.0 : (pulse ? 1.05 : 0.96))
                                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
                                .opacity(coreFade)
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.18), radius: 20, y: 10)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.white.opacity(0.00),
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.30),
                                    Color.white.opacity(0.00)
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 0.7)
                        .rotationEffect(.degrees(ringRotation))
                        .animation(
                            .linear(duration: softenMotion ? 2.0 : 1.4).repeatForever(
                                autoreverses: false
                            ),
                            value: ringRotation
                        )
                        .opacity((softenMotion ? 0.7 : 1.0) * (fadeOut ? 0 : 1))
                        .animation(.easeOut(duration: 0.35), value: fadeOut)

                    Circle()
                        .stroke(Color.black.opacity(0.20), lineWidth: 12)
                        .blur(radius: 18)
                        .opacity((softenMotion ? 0.55 : (pulse ? 0.9 : 0.55)) * (fadeOut ? 0 : 1))
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                        .animation(.easeOut(duration: 0.35), value: fadeOut)

                    VStack(spacing: 10) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.mmSecondary)

                        Text("공간을 구성 중…")
                            .font(.caption)
                            .foregroundStyle(.mmSecondary)
                    }
                    .padding(.top, base * 0.92)
                    .opacity(fadeOut ? 0 : 1)
                    .animation(.easeOut(duration: 0.25), value: fadeOut)
                }
                .frame(width: portalSize + 25, height: portalSize)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(preZoom ? 1.08 : (pulse ? 1.01 : 0.99))
                .opacity(fadeOut ? 0 : 1)
                .blur(radius: coverStage == 2 ? 8 : 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.95), value: preZoom)
                .animation(.spring(response: 0.85, dampingFraction: 0.92), value: coverStage)
                .animation(.easeOut(duration: 0.35), value: fadeOut)
                .onAppear {
                    ringRotation = 360
                    pulse = true

                    if isReady, !didRunFinish {
                        didRunFinish = true
                        finishSequence()
                    }
                }
                .onChange(of: isReady) { _, ready in
                    guard ready else { return }
                    guard !didRunFinish else { return }
                    didRunFinish = true
                    finishSequence()
                }
            }
        }
        .allowsHitTesting(true)
    }

    private func finishSequence() {
        withAnimation(.easeOut(duration: 0.25)) {
            softenMotion = true
        }

        withAnimation(.spring(response: 0.75, dampingFraction: 0.92)) {
            preZoom = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.90, dampingFraction: 0.90)) {
                coverStage = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.spring(response: 0.95, dampingFraction: 0.92)) {
                coverStage = 2
            }
        }

        // 화이트 코어부터 녹여서 밑의 RealityView가 스며나오게
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
            withAnimation(.easeOut(duration: 0.55)) {
                coreFade = 0.0
            }
        }

        // 오버레이 전체 페이드는 조금 더 뒤에(코어가 어느 정도 녹고 난 뒤)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.74) {
            withAnimation(.easeOut(duration: 0.45)) {
                fadeOut = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            onFinished()
        }
    }
}
