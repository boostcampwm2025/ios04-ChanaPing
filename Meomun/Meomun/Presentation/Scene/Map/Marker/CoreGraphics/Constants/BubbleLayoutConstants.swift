//
//  BubbleLayoutConstants.swift
//  Meomun
//
//  Created by MinwooJe on 2/4/26.
//

import CoreGraphics

/// 버블 레이아웃 상수 (실제 사용 값만 관리, Y 좌표는 Factory에서 계산)
struct BubbleLayoutConstants {
    // 전체 크기
    static let width: CGFloat = 170
    static let height: CGFloat = 103
    static let cornerRadius: CGFloat = 22

    // 패딩 (MessageBubble.swift와 동일)
    static let paddingTop: CGFloat = 1
    static let paddingVertical: CGFloat = 7
    static let paddingHorizontal: CGFloat = 10

    // VStack spacing (MessageBubble line 42)
    static let sectionSpacing: CGFloat = 5

    // Location (MessageBubble line 79-89)
    static let locationIconSize: CGFloat = 15
    static let locationIconSpacing: CGFloat = 4
    static let locationTopPadding: CGFloat = 4

    // Text (MessageBubble line 153-164)
    static let textFontSize: CGFloat = 14
    static let textHeight: CGFloat = 36  // fixedSize layout
    static let textLineLimit: Int = 2

    // Date (MessageBubble line 106-109)
    static let dateFontSize: CGFloat = 11

    // PlaceIcon (DecoratedMessageBubble line 10-12, 79-91)
    static let placeIconSize: CGFloat = 30
    static let placeIconOffsetY: CGFloat = -15
    static let placeIconBackgroundOffset: CGFloat = 3

    // Chevron (MessageBubble line 134-144)
    static let chevronIconSize: CGFloat = 15
    static let chevronBackgroundSize: CGFloat = 20

    // StackBack (StackBack.swift)
    static let stackBackOffset1 = CGSize(width: 14, height: 14)
    static let stackBackOffset2 = CGSize(width: 7, height: 7)

    // Rotation (RotatingMessageStack.swift)
    static let rotationMovingDistance: CGFloat = 16
}
