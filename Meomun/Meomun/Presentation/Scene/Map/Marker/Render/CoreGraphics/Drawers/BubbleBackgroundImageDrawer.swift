//
//  BubbleBackgroundImageDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/5/26.
//

import SwiftUI
import UIKit

struct BubbleBackgroundImageDrawer: BubbleDrawable {
    private let rect: CGRect
    private let hasPlaceTag: Bool

    init(rect: CGRect, hasPlaceTag: Bool) {
        self.rect = rect
        self.hasPlaceTag = hasPlaceTag
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let image = hasPlaceTag
            ? UIImage(resource: .bubbleBackgroundWithPlace)
            : UIImage(resource: .bubbleBackgroundNoPlace)

        // WithPlace 에셋은 아이콘 + 버블 전체 한 장 -> 캔버스 전체(origin.y=0, height=rect.maxY)에 그림
        let drawRect = hasPlaceTag
            ? CGRect(x: 0, y: 0, width: rect.width, height: rect.maxY)
            : rect
        image.draw(in: drawRect)
    }
}
