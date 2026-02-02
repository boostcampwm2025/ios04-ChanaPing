//
//  SpaceTopBar.swift
//  Meomun
//
//  Created by 지연 on 2/3/26.
//

import SwiftUI

struct SpaceTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            titleLabel
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                BackButton(action: onBack)
                Spacer()
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(topFade)
    }

    private var titleLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.12))
                .blur(radius: 8)
        )
    }

    private var topFade: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.30),
                .black.opacity(0.10),
                .black.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    ZStack {
        SpaceTopBar(title: "판교동행정복지센터") {
            print("hi")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.mmBackground)
}
