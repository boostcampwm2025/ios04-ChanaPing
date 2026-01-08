//
//  FloatingTabBar.swift
//  Meomun
//
//  Created by 지연 on 1/6/26.
//

import SwiftUI

struct FloatingTabBar: View {
    let selectedTab: MainTab
    let onSelect: (MainTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            FloatingTabItem(
                systemImageName: "map",
                isSelected: selectedTab == .map
            ) {
                onSelect(.map)
            }

            FloatingTabItem(
                systemImageName: "archivebox",
                isSelected: selectedTab == .record
            ) {
                onSelect(.record)
            }

            FloatingTabItem(
                systemImageName: "person",
                isSelected: selectedTab == .myPage
            ) {
                onSelect(.myPage)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            CornerRadiusShape(
                topLeft: 24,
                topRight: 24,
                bottomLeft: 10,
                bottomRight: 10
            )
                .fill(.white.opacity(0.96))
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 18,
                    x: 0,
                    y: 6
                )
        )
        .padding(.horizontal, 24)
        .animation(
            .spring(
                response: 0.25,
                dampingFraction: 0.9
            ),
            value: selectedTab
        )
    }
}

#Preview {
    FloatingTabBar(selectedTab: .map) { _ in
        print("hi")
    }
}
