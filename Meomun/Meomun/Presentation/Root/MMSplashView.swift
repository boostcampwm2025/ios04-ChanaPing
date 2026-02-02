//
//  SplashView.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

struct MMSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: CGFloat

    @State private var contentOpacity: CGFloat = 0
    @State private var contentScale: CGFloat = 0.98

    var body: some View {
        ZStack {
            FloatingDecoBackground(
                backgroundSpeed: 22
            )

            VStack {
                CloudDotsLoadingView(progress: progress)
                .frame(width: 260, height: 140)

                Text("나만의 공간 아카이브를 여는 중…")
                    .font(.system(size: 16))
                    .foregroundStyle(.tabActive)
                    .padding(.top, -20)
            }
            .opacity(contentOpacity)
            .scaleEffect(contentScale)
            .onAppear(perform: animateEntranceIfNeeded)
        }
    }
}

// MARK: - Entrance Animation

private extension MMSplashView {
    func animateEntranceIfNeeded() {
        guard !reduceMotion else {
            contentOpacity = 1
            contentScale = 1
            return
        }

        contentOpacity = 0
        contentScale = 0.98

        withAnimation(.easeOut(duration: 0.28)) {
            contentOpacity = 1
            contentScale = 1
        }
    }
}

#Preview {
    MMSplashView(progress: 1)
}
