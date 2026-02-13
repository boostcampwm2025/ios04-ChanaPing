//
//  BubbleStyleConstants.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import SwiftUI

struct BubbleStyleConstants {
    struct Colors {
        static let background: UIColor = .mmBubbleBackground
        static let textPrimary: UIColor = .mmTextPrimary
        static let textSecondary: UIColor = .mmTextSecondary
        static let tabActive: UIColor = .mmTabActive
        static let locationIconColor: UIColor = UIColor(red: 0x53/255, green: 0x80/255, blue: 0x8C/255, alpha: 1.0)

        static let stackBack1 = UIColor(red: 0xE6/255, green: 0xE6/255, blue: 0xE6/255, alpha: 1.0)
        static let stackBack2 = UIColor(red: 0xF4/255, green: 0xF4/255, blue: 0xF4/255, alpha: 1.0)
    }

    // 폰트
    struct Fonts {
        static let location = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let text = UIFont.systemFont(ofSize: 14, weight: .regular)
        static let date = UIFont.systemFont(ofSize: 11, weight: .semibold)
    }

    // 그림자
    struct Shadow {
        static let color = UIColor.black.withAlphaComponent(0.06)
        static let offset = CGSize(width: 0, height: 6)
        static let radius: CGFloat = 12
    }

    // 그라데이션 테두리
    struct GradientStroke {
        static let lineWidth: CGFloat = 1

        enum ColorType {
            case green  // placeTag 있을 때
            case gray   // placeTag 없을 때

            func colors(colorScheme: ColorScheme) -> [UIColor] {
                let tabActive = Colors.tabActive

                switch self {
                case .green:
                    return [
                        tabActive.withAlphaComponent(0.75),
                        tabActive.withAlphaComponent(0.22)
                    ]
                case .gray:
                    return [
                        UIColor.gray.withAlphaComponent(0.65),
                        UIColor.gray.withAlphaComponent(0.22)
                    ]
                }
            }
        }

        static let startPoint = CGPoint(x: 0, y: 0)  // topLeading
        static let endPoint = CGPoint(x: 1, y: 1)    // bottomTrailing
    }
}
