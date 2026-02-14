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
    private let image: UIImage

    init(rect: CGRect, hasPlaceTag: Bool) {
        self.rect = rect
        self.hasPlaceTag = hasPlaceTag
        self.image = hasPlaceTag
            ? UIImage(resource: .bubbleBackgroundWithPlace)
            : UIImage(resource: .bubbleBackgroundNoPlace)
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        // WithPlace: 아이콘 + 버블 전체 한 장 -> rect 기준으로 아이콘 상단 포함 영역에 그림
        // NoPlace: 스택백 포함 이미지 -> rect 기준으로 스택백 오프셋 포함 영역에 그림
        let drawRect = hasPlaceTag
            ? CGRect(
                x: rect.minX,
                y: rect.minY - BubbleLayoutConstants.placeIconTopInset,
                width: rect.width,
                height: BubbleLayoutConstants.placeIconTopInset + rect.height
            )
            : CGRect(
                x: rect.minX,
                y: rect.minY,
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
