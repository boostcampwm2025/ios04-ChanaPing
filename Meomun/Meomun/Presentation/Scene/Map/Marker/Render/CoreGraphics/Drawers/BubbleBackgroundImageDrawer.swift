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

        // WithPlace: 아이콘 + 버블 전체 한 장 -> 캔버스 전체에 그림
        // NoPlace: 스택백 포함 이미지 -> 캔버스 전체(rect + stackBack offset)에 그림
        let drawRect = hasPlaceTag
            ? CGRect(x: 0, y: 0, width: rect.width, height: rect.maxY)
            : CGRect(
                x: 0,
                y: 0,
                width: rect.width + BubbleLayoutConstants.stackBackOffset1.width,
                height: rect.height + BubbleLayoutConstants.stackBackOffset1.height
            )

        context.saveGState()
        context.setShadow(
            offset: BubbleStyleConstants.Shadow.offset,
            blur: BubbleStyleConstants.Shadow.radius,
            color: BubbleStyleConstants.Shadow.color.cgColor
        )
        image.draw(in: drawRect)
        context.restoreGState()
    }
}
