//
//  BubbleChevronDrawer.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleChevronDrawer: BubbleDrawable {
    private let point: CGPoint
    private let image: UIImage

    init(point: CGPoint) {
        self.point = point
        self.image = UIImage(resource: .rotatingBubbleChevron)
    }

    func draw(in context: CGContext, colorScheme: ColorScheme) {
        let size = BubbleLayoutConstants.chevronBackgroundSize
        let imageRect = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        image.draw(in: imageRect)
    }
}
