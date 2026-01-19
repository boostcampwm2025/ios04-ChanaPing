//
//  ToastModifier.swift
//  Meomun
//
//  Created by Hayeon Park on 1/19/26.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    let message: String?
    let duration: Duration
    let bottomPadding: CGFloat
    let onDismiss: () -> Void

    init(
        message: String?,
        duration: Duration = .seconds(2),
        bottomPadding: CGFloat = 32,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.duration = duration
        self.bottomPadding = bottomPadding
        self.onDismiss = onDismiss
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                ToastView(message: message)
                    .padding(.bottom, bottomPadding)
                    .transition(.opacity)
                    .task(id: message) {
                        try? await Task.sleep(for: duration)
                        await MainActor.run { onDismiss() }
                    }
            }
        }
        .animation(.easeInOut, value: message)
    }
}

extension View {
    func toast(
        _ message: String?,
        duration: Duration = .seconds(2),
        bottomPadding: CGFloat = 32,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            ToastModifier(
                message: message,
                duration: duration,
                bottomPadding: bottomPadding,
                onDismiss: onDismiss
            )
        )
    }
}
