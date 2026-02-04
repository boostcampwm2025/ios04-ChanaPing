//
//  SpyBubbleRenderer.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
@testable import Meomun

final class SpyBubbleRenderer: BubbleImageRendering {
    private(set) var singleCount = 0
    private(set) var rotatingCount = 0

    func setColorScheme(_ traitCollection: UITraitCollection) {}

    func renderSingleBubble(
        message: Message,
        scale: CGFloat? = nil
    ) async -> UIImage {

        singleCount += 1
        return UIImage()
    }

    func renderRotatingBubble(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat? = nil
    ) async -> UIImage {

        rotatingCount += 1
        return UIImage()
    }
}
