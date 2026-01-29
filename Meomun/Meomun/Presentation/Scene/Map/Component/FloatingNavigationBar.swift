//
//  FloatingNavigationBar.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import SwiftUI

struct FloatingNavigationBar: View {
    let title: String
    let onTapSearch: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Image("cloud")
                .resizable()
                .scaledToFit()
                .frame(width: 32)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.meomunTextTitle)

            Spacer()

            Button(action: onTapSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Color.meomunTextTitle)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            CornerRadiusShape(
                topLeft: 10,
                topRight: 10,
                bottomLeft: 24,
                bottomRight: 24
            )
            .fill(Color.meomunFloatingBackground)
            .shadow(color: .black.opacity(0.12),
                    radius: 18,
                    x: 0,
                    y: 6)
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()

        FloatingNavigationBar(
            title: "머문",
            onTapSearch: {}
        )
        .padding(.top, 12)
    }
}
