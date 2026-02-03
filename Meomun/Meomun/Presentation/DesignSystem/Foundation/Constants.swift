//
//  Constants.swift
//  Meomun
//
//  Created by MinwooJe on 1/30/26.
//

import SwiftUI

enum MMSpacing {
    /// Floating 컴포넌트(탭바, 캐러셀 등)의 좌우 여백
    static let floatingHorizontalPadding: CGFloat = 30

    /// Floating 컨테이너 내부 수직 여백
    static let floatingVerticalPadding: CGFloat = 22

    /// Floating 컨테이너 내부 수평 여백
    static let floatingInnerHorizontalPadding: CGFloat = 22
}

enum MMCornerRadius {
    static let floatingContainerTop: CGFloat = 24
    static let floatingContainerBottom: CGFloat = 10
}

enum MMLayout {
    /// 네비게이션 툴 아래 컴포넌트를 올릴 때 사용하는 top offset
    static let belowNavigationToolbarOffset: CGFloat = 70

    /// 탭바 위에 컴포넌트를 올릴 때 사용하는 bottom offset (탭바 + 여유 공간)
    static let aboveTabBarOffset: CGFloat = 90

    /// 탭바 높이를 고려한 기본 bottom offset
    static let tabBarBottomOffset: CGFloat = 96
}
