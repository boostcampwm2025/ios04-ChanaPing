//
//  MMFloatingNavigationBar.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct MMFloatingNavigationBar: View {
    let title: String
    let onTapSearch: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 12) {
                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.mmTextTitle)
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

            Spacer()

            Button(action: onTapSearch) {
                Image(systemName: "magnifyingglass")
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
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()

        MMFloatingNavigationBar(
            title: "머문",
            onTapSearch: {}
        )
        .padding(.top, 12)
    }
}
