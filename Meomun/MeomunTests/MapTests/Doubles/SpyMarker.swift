//
//  SpyMarker.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
@testable import Meomun

final class SpyMarker: MarkerProtocol {
    var alpha: CGFloat = 0

    private(set) var iconSetCount = 0
    private(set) var attachedHistory: [Bool] = []
    private var tapHandler: (() -> Void)?

    func setIcon(_ image: UIImage) {
        iconSetCount += 1
    }

    func setAttached(to mapView: MapViewProtocol?) {
        attachedHistory.append(mapView != nil)
    }

    func setOnTap(_ handler: @escaping () -> Void) {
        tapHandler = handler
    }

    // 테스트 편의용
    func simulateTap() { tapHandler?() }
}
