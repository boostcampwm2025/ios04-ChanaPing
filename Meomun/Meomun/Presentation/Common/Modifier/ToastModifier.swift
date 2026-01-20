//
//  ToastModifier.swift
//  Meomun
//
//  Created by Hayeon Park on 1/19/26.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?

    let duration: Duration
    let bottomPadding: CGFloat

    init(
        message: Binding<String?>,
        duration: Duration = .seconds(2),
        bottomPadding: CGFloat = 32
    ) {
        self._message = message
        self.duration = duration
        self.bottomPadding = bottomPadding
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                ToastView(message: message)
                    .padding(.bottom, bottomPadding)
                    .transition(.opacity)
                    .task(id: message) {
                        do {
                            try await Task.sleep(for: duration)
                        } catch {
                            return
                        }
                        await MainActor.run {
                            self.message = nil
                        }
                    }
            }
        }
        .animation(.easeInOut, value: message)
    }
}

extension View {
    func toast(
        _ message: Binding<String?>,
        duration: Duration = .seconds(2),
        bottomPadding: CGFloat = 32
    ) -> some View {
        modifier(
            ToastModifier(
                message: message,
                duration: duration,
                bottomPadding: bottomPadding,
            )
        )
    }
}
