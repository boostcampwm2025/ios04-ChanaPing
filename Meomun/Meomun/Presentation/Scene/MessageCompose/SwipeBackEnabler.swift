//
//  SwipeBackEnabler.swift
//  Meomun
//
//  Created by 지연 on 1/26/26.
//

import SwiftUI
import UIKit

struct SwipeBackEnabler: UIViewControllerRepresentable {
    // swipe 가능 여부 판단 클로저
    let shouldBegin: () -> Bool

    // swipe 시도했지만 막혔을 때 실행할 콜백
    let onAttempt: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldBegin: shouldBegin, onAttempt: onAttempt)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        context.coordinator.shouldBegin = shouldBegin
        context.coordinator.onAttempt = onAttempt

        DispatchQueue.main.async {
            guard let navigationController = viewController.navigationController,
                  let gesture = navigationController.interactivePopGestureRecognizer
            else { return }

            gesture.isEnabled = true
            gesture.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var shouldBegin: () -> Bool
        var onAttempt: (() -> Void)?

        init(shouldBegin: @escaping () -> Bool, onAttempt: (() -> Void)?) {
            self.shouldBegin = shouldBegin
            self.onAttempt = onAttempt
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            let allowed = shouldBegin()

            if !allowed {
                // swipe pop 차단 + 시도했음을 상위에 알림
                DispatchQueue.main.async { [weak self] in
                    self?.onAttempt?()
                }
            }

            return allowed
        }
    }
}

extension View {
    func enableSwipeBack(
        shouldBegin: @escaping () -> Bool,
        onAttempt: (() -> Void)? = nil
    ) -> some View {
        background(
            SwipeBackEnabler(
                shouldBegin: shouldBegin,
                onAttempt: onAttempt
            )
        )
    }
}
