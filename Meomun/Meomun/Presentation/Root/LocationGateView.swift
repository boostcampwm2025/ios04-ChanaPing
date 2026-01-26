//
//  LocationGateView.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import SwiftUI
import CoreLocation

fileprivate enum Constants {
    // Title
    static let loadingMessage = "현재 위치 불러오는 중..."

    // UI
    static let dimOpacity: Double = 0.4
    static let popupCornerRadius: CGFloat = 16
    static let popupInset: CGFloat = 24
    static let popupHorizontalPadding: CGFloat = 32
    static let popupContentSpacing: CGFloat = 20
    static let descriptionSpacing: CGFloat = 6
}

struct LocationGateView: View {
    @EnvironmentObject private var locationProvider: LocationProvider
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    private let onReady: (Coordinate) -> Void

    init(onReady: @escaping (Coordinate) -> Void) {
        self.onReady = onReady
    }

    var body: some View {
        Group {
            switch locationProvider.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                ProgressView(Constants.loadingMessage)
                    .task(id: locationProvider.current) {
                        if let coordinate = locationProvider.current {
                            onReady(coordinate)
                        }
                    }
                // TODO: - 타임아웃 처리 -> "현재 위치를 불러올 수 없어요. 잠시 후 다시 시도해주세요."

            case .denied, .restricted:
                AlertView(type: .location) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }

            default:
                EmptyView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in      // "다음번에 묻기 또는 내가 공유할 때" 선택 후 앱 진입 시 얼럿을 다시 띄우기 위함.
            if newPhase == .active {
                locationProvider.requestAuthorizationIfNeeded()
            }
        }
    }
}
