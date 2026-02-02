//
//  MMFloatingNavigationBar.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct MMFloatingNavigationBar: View {
    let config: MMFloatingNavBarConfiguration

    var body: some View {
        HStack(alignment: .center) {
            leftTitle
                .animation(.spring(response: 0.32, dampingFraction: 0.48), value: config.title)
            Spacer()
            rightButton
                .animation(.spring(response: 0.32, dampingFraction: 0.48), value: config.rightItem)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.25), value: config)
    }
}

private extension MMFloatingNavigationBar {
    private var leftTitle: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("cloud")
                .resizable()
                .scaledToFit()
                .frame(width: 32)

            Text(config.title)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.mmTextTitle)
                .contentTransition(.opacity)
        }
        .padding(10)
        .padding(.horizontal, 5)
        .background(
            CornerRadiusShape(
                topLeft: 25,
                topRight: 25,
                bottomLeft: 0,
                bottomRight: 25
            )
            .fill(Color.mmFloatingBackground.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.12),
                radius: 18,
                x: 0,
                y: 6)
    }

    @ViewBuilder
    private var rightButton: some View {
        switch config.rightItem {
        case .search(let action):
            circleButton(
                systemName: "magnifyingglass",
                action: action
            )

        case .edit(let isEditing, let action):
            circleButton(
                systemName: isEditing ? "checkmark" : "pencil",
                action: action
            )

        case .none:
            EmptyView()
        }
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color.mmTextTitle)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.mmFloatingBackground.opacity(0.85))
                        .shadow(color: .black.opacity(0.12),
                                radius: 18,
                                x: 0,
                                y: 6)
                )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()

        MMFloatingNavigationBar(
            config: .init(
                title: "머문",
                rightItem: .search(
                    action: { print("search") }
                )
            )
        )
        .padding(.top, 12)
    }
}
