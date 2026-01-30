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
        HStack(spacing: 2) {
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
                systemImageName: "gearshape",
                isSelected: selectedTab == .setting
            ) {
                onSelect(.setting)
            }
        }
        .floatingContainer()
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
