//
//  BubbleClipDrawable.swift
//  Meomun
//
//  Created by MinwooJe on 2/13/26.
//

import SwiftUI

/// 애니메이션 영역 클리핑용 Drawable. 이후 모든 drawable의 그리기를 clipRect으로 제한.
struct BubbleClipDrawable: BubbleDrawable {
    private let clipRect: CGRect

    init(clipRect: CGRect) {
        self.clipRect = clipRect
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        context.clip(to: clipRect)
    }
}
