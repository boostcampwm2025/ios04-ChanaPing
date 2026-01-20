//
//  LoadingOverlayView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/21/26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let message: String

    init(message: String = "") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.meomunPointColor)

                Text(message)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.meomunPrimaryColor)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.05), radius: 2)
                    .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
            )
        }
    }
}

#Preview {
    LoadingOverlayView(message: "머문 흔적을 남기고 있어요")
}
