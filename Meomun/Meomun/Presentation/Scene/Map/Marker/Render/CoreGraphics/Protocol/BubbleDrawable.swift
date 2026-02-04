//
//  BubbleDrawable.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import CoreGraphics
import SwiftUI

protocol BubbleDrawable {
    /// CGContext에 요소를 그립니다
    func draw(in context: CGContext, colorScheme: ColorScheme)
}
