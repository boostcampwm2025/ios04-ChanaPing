//
//  MainMapViewController.swift
//  Fleeting-Prototype
//
//  Created by MinwooJe on 12/18/25.
//

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

final class MainMapViewController: UIViewController {

}
