//
//  LoadingOverlayView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/21/26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let status: LoadingStatus
    let message: String?

    init(status: LoadingStatus = .loading, message: String? = nil) {
        self.status = status
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Group {
                    if status == .loading {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.meomunPointColor)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.meomunPointColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                if let message {
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.meomunPrimaryColor)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.05), radius: 2)
                    .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
            )
        }
        .animation(.spring(duration: 0.3), value: status)
    }
}

#Preview {
    LoadingOverlayView()
}
