//
//  AlertView.swift
//  Meomun
//
//  Created by MinwooJe on 1/26/26.
//

import SwiftUI

fileprivate enum Constants {
    static let dimOpacity: Double = 0.4
    static let popupCornerRadius: CGFloat = 16
    static let popupInset: CGFloat = 24
    static let popupHorizontalPadding: CGFloat = 32
    static let popupContentSpacing: CGFloat = 20
    static let descriptionSpacing: CGFloat = 6
}

enum AlertType {
    struct AlertConfiguration {
        let image: Image
        let title: String
        let description: String
        let buttonTitle: String
    }

    case location
    case network

    var config: AlertConfiguration {
        switch self {
        case .location:
                .init(
                    image: Image(systemName: "location.slash.fill"),
                    title: "위치 권한이 필요해요",
                    description: "위치 접근을 허용하고 지도 위에 기록을 남겨봐요!",
                    buttonTitle: "위치 권한 설정하기"
                )
        case .network:
                .init(
                    image: Image(systemName: "network.slash"),
                    title: "인터넷 연결에 문제가 있어요",
                    description: "인터넷 연결 상태를 확인하고 다시 시도해주세요!",
                    buttonTitle: "새로고침"
                )
        }
    }
}

struct AlertView: View {
    private let titleImage: Image
    private let title: String
    private let description: String
    private let buttonTitle: String

    private let onTapButton: () -> Void

    init(type: AlertType, onTapButton: @escaping () -> Void) {
        self.titleImage = type.config.image
        self.title = type.config.title
        self.description = type.config.description
        self.buttonTitle = type.config.buttonTitle
        self.onTapButton = onTapButton
    }

    var body: some View {
        ZStack {
            Color.black.opacity(Constants.dimOpacity)
                .ignoresSafeArea()

            VStack(spacing: Constants.popupContentSpacing) {
                titleImageView

                VStack(spacing: Constants.descriptionSpacing) {
                    titleText
                    descriptionText
                }

                ctaButton
            }
            .padding(Constants.popupInset)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.popupCornerRadius))
            .padding(.horizontal, Constants.popupHorizontalPadding)
        }
    }
}

extension AlertView {
    private var titleImageView: some View {
        titleImage
            .font(.largeTitle)
            .imageScale(.large)
            .foregroundStyle(.secondary)
    }

    private var titleText: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
    }

    private var descriptionText: some View {
        Text(description)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var ctaButton: some View {
        Button {
            onTapButton()
        } label: {
            Text(buttonTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    AlertView(type: .location) {
        print("로케이션 버튼 탭")
    }

    AlertView(type: .network) {
        print("네트워크 버튼 탭")
    }
}
