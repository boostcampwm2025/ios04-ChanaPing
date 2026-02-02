//
//  FloatingTabBar.swift
//  Meomun
//
//  Created by 지연 on 1/6/26.
//

import SwiftUI

struct MMFloatingTabBar: View {
    let selectedTab: MainTab
    let onSelect: (MainTab) -> Void

    var body: some View {
        HStack(spacing: 2) {
            MMFloatingTabBarItem(
                systemImageName: "map",
                isSelected: selectedTab == .map
            ) {
                onSelect(.map)
            }

            MMFloatingTabBarItem(
                systemImageName: "archivebox",
                isSelected: selectedTab == .record
            ) {
                onSelect(.record)
            }

            MMFloatingTabBarItem(
                systemImageName: "gearshape",
                isSelected: selectedTab == .setting
            ) {
                onSelect(.setting)
            }
        }
        .mmFloatingContainer()
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
    MMFloatingTabBar(selectedTab: .map) { _ in
        print("hi")
    }
}
