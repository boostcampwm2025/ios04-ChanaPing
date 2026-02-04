//
//  BubbleCompositor.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI
import UIKit

/// 최종 이미지 합성 책임
struct BubbleCompositor {
    private let size: CGSize
    private let colorScheme: ColorScheme
    private let scale: CGFloat

    init(size: CGSize, colorScheme: ColorScheme, scale: CGFloat = UIScreen.main.scale) {
        self.size = size
        self.colorScheme = colorScheme
        self.scale = scale
    }

    /// Drawable 배열을 순차적으로 렌더링하여 최종 이미지 생성.
    /// - Parameters:
    ///   - drawables: 그릴 Drawable 배열
    ///   - over: nil이면 clear 후 그리기, 있으면 이 이미지를 먼저 그린 뒤 drawables 그리기 (캐시 베이스 + 애니메이션 레이어 합성용)
    func render(drawables: [BubbleDrawable], over baseImage: UIImage? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { rendererContext in
            let context = rendererContext.cgContext

            if let base = baseImage {
                base.draw(in: CGRect(origin: .zero, size: size))
            } else {
                context.clear(CGRect(origin: .zero, size: size))
            }

            for drawable in drawables {
                drawable.draw(in: context, colorScheme: colorScheme)
            }
        }
    }
}
