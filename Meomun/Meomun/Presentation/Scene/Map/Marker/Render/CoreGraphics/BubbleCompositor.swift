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

    init(size: CGSize, colorScheme: ColorScheme = .light, scale: CGFloat = UIScreen.main.scale) {
        self.size = size
        self.colorScheme = colorScheme
        self.scale = scale
    }

    /// Drawable 배열을 순차적으로 렌더링하여 최종 이미지 생성.
    /// - Parameters:
    ///   - drawables: 그릴 Drawable 배열
    ///   - baseImage: nil이면 clear 후 그리기, 있으면 이 이미지를 먼저 그린 뒤 drawables 그리기 (캐시 베이스 + 애니메이션 레이어 합성용)
    ///   - opaque: false면 투명 배경 (위치 레이어 캐시용)
    func render(drawables: [BubbleDrawable], over baseImage: UIImage? = nil, opaque: Bool = true) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = opaque

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

    /// 베이스 이미지 위에 상단 이미지(예: 위치 레이어)를 겹쳐 합성. 캐시 레이어 합성용.
    func composite(base: UIImage, top: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            top.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
