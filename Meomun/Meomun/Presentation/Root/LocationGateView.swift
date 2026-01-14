//
//  LocationGateView.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import SwiftUI
import CoreLocation

struct LocationGateView: View {
    @EnvironmentObject private var locationProvider: LocationProvider
    @State private var didSendReady = false
    let onReady: (Coordinate) -> Void

    var body: some View {
        Group {
            switch locationProvider.authorizationStatus {
            case .notDetermined:
                Text("위치 권한을 요청 중...")

            case .denied, .restricted:
                // 설정으로 이동 안내 화면
                EmptyView()

            case .authorizedWhenInUse, .authorizedAlways:
                if let current = locationProvider.current {
                    Color.clear
                        .task {
                            guard !didSendReady else { return }
                            didSendReady = true
                            onReady(current)
                        }
                } else {
                    ProgressView("현재 위치 불러오는 중...")
                }

            @unknown default:
                Text("알 수 없는 권한 상태")
            }
        }
        .task {
            locationProvider.requestAuthorizationIfNeeded()
        }
    }
}
