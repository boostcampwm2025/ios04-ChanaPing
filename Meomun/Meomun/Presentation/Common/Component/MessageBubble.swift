//
//  MessageBubble.swift
//  Meomun
//
//  Created by 지연 on 1/7/26.
//

import SwiftUI

/// 1) 버블 내부 텍스트 rotate 기능 지원 X 시
///     - placeName 있을 수도 / 없을 수도
///     - 좌측 라인 visible
/// 2) 버블 내부 텍스트 rotate 기능 지원 O 시
///     - placeName 항상 있음
///     - 좌측 라인 invisible

struct MessageBubble: View {
    let text: String
    let placeName: String?
    let isRecent: Bool
    let showsAccentLine: Bool
    var maxWidth: CGFloat = 210

    private var accentColor: Color {
        if !showsAccentLine {
            return Color.clear
        }
        return isRecent ? Color.orange : Color.blue
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 왼쪽 세로 라인
            Capsule()
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 11)

            VStack(alignment: .leading, spacing: 6) {
                // 장소 태그 (옵셔널)
                if let placeName, !placeName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#53808C"))

                        Text(placeName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.gray.opacity(0.8))
                    }
                }

                // 본문 (최대 2줄)
                Text(text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 13)
            .padding(.trailing, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06),
                        radius: 12,
                        x: 0,
                        y: 6)
        )
        .frame(maxWidth: maxWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()

        VStack(alignment: .leading, spacing: 24) {
            MessageBubble(
                text: "오늘 좀 춥다🫥🍃",
                placeName: "장소 이름",
                isRecent: false,
                showsAccentLine: true
            )

            MessageBubble(
                text: "🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥🫥",
                placeName: "장소 이름",
                isRecent: false,
                showsAccentLine: false
            )

            MessageBubble(
                text: "최근에 남긴 따끈따끈한 메시지라서 주황색 라인으로 표시",
                placeName: nil,
                isRecent: true,
                showsAccentLine: true
            )
        }
    }
}
