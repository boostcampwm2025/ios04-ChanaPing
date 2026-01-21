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
    static let permissionTitle = "위치 권한 필요"
    static let permissionMessage = "머문에서 위치를 사용할 수 없습니다.\n위치 권한을 허용해주세요."
    static let settingsButtonTitle = "위치 권한 설정하기"

    // Image
    static let locationImage = "location.slash.fill"
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

            case .denied, .restricted:
                permissionDeniedView

            case .notDetermined:
                EmptyView()

            @unknown default:
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

extension LocationGateView {
    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: Constants.locationImage)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(Constants.permissionTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(Constants.permissionMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(Constants.settingsButtonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .padding(.horizontal)
    }
}
