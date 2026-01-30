//
//  LoadingOverlayView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/21/26.
//

import SwiftUI

private enum Layout {
    static let iconSize: CGFloat = 40
    static let textMaxWidth: CGFloat = 160
    static let textMaxHeight: CGFloat = 38

    static let cardSideNoMessage: CGFloat = 100
    static let cardWidthWithMessage: CGFloat = 210
    static let cardHeightWithMessage: CGFloat = 150

    static let iconToTextSpacing: CGFloat = 15
    static let topPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 10
    static let verticalPadding: CGFloat = 10
}

struct LoadingOverlayView: View {
    let status: LoadingStatus
    let message: String?

    @State private var isPresented = false

    init(status: LoadingStatus = .loading, message: String? = nil) {
        self.status = status
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            content
                .frame(width: cardSize.width, height: cardSize.height)
                .background(cardBackground)
                .scaleEffect(isPresented ? 1.0 : 0.98)
                .opacity(isPresented ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = true
            }
        }
        .onDisappear { isPresented = false }
        .animation(.spring(duration: 0.3), value: status)
    }
}

private extension LoadingOverlayView {
    @ViewBuilder var statusIcon: some View {
        switch status {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .tint(.mmPoint)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Layout.iconSize))
                .foregroundStyle(Color.mmPoint)
                .transition(.scale.combined(with: .opacity))
        case .fail:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: Layout.iconSize))
                .foregroundStyle(Color.red)
                .transition(.scale.combined(with: .opacity))
        case .idle:
            EmptyView()
        }
    }
}

private extension LoadingOverlayView {
    var hasMessage: Bool {
        guard let message else { return false }
        return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    var content: some View {
        if hasMessage {
            messageContent
        } else {
            centeredIconContent
        }
    }

    var centeredIconContent: some View {
        statusIcon
            .frame(width: Layout.iconSize, height: Layout.iconSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var messageContent: some View {
        VStack(spacing: Layout.iconToTextSpacing) {
            statusIcon
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .padding(.top, Layout.topPadding)

            Text(message ?? "")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: false)
                .frame(maxWidth: Layout.textMaxWidth, maxHeight: Layout.textMaxHeight)
                .padding(.bottom, Layout.bottomPadding)
        }
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(0.8))
            .shadow(color: .black.opacity(0.05), radius: 2)
            .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)
    }

    var cardSize: CGSize {
        hasMessage
        ? CGSize(width: Layout.cardWidthWithMessage, height: Layout.cardHeightWithMessage)
        : CGSize(width: Layout.cardSideNoMessage, height: Layout.cardSideNoMessage)
    }
}

#Preview {
    let loadingMessage = "머문 흔적을 남기고 있어요."
    let successMessage = "머문 흔적을 남겼어요."
    let failMessage = "머문 흔적 남기기에 실패했어요."

    VStack(alignment: .center) {
        LoadingOverlayView()
        LoadingOverlayView(status: .loading, message: loadingMessage)
        LoadingOverlayView(status: .success, message: successMessage )
        LoadingOverlayView(status: .fail, message: failMessage)
    }
}
