//
//  BubbleClipDrawable.swift
//  Meomun
//
//  Created by MinwooJe on 2/13/26.
//

import SwiftUI

/// 애니메이션 영역 클리핑용 Drawable. children의 그리기를 clipRect으로 제한.
struct BubbleClipDrawable: BubbleDrawable {
    private let clipRect: CGRect
    private let children: [BubbleDrawable]

    init(clipRect: CGRect, children: [BubbleDrawable]) {
        self.clipRect = clipRect
        self.children = children
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        context.saveGState()
        context.clip(to: clipRect)

        for child in children {
            child.draw(in: context, colorScheme: colorScheme)
        }

        context.restoreGState()
    }
}
