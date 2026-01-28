//
//  MyPageView.swift
//  Meomun
//
//  Created by hoon on 1/28/26.
//

import CoreLocation
import SwiftUI

struct MyPageView: View {
    @State private var isResetAlertPresented = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            // 정보
            Section("정보") {
                AppVersionRow()

                NavigationRow(title: "이용약관") {
                    TermsOfServiceView()
                }

                NavigationRow(title: "개인정보처리방침") {
                    PrivacyPolicyView()
                }

                NavigationRow(title: "오픈소스 라이선스") {
                    OpenSourceLicensesView()
                }
            }

            // 권한
            Section("권한") {
                PermissionStatusRow(
                    title: "위치 권한",
                    status: LocationPermissionStatus.current.displayText,
                    statusKind: LocationPermissionStatus.current.kind
                )

                Button("앱 설정으로 이동") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    openURL(url)
                }
            }

            // 데이터
            Section("데이터") {
                Text("앱 데이터 초기화 시 모든 로컬 데이터가 삭제되며, 이 작업은 되돌릴 수 없습니다.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button(role: .destructive) {
                    isResetAlertPresented = true
                } label: {
                    Text("앱 데이터 초기화")
                }
                .alert("앱 데이터를 초기화할까요?", isPresented: $isResetAlertPresented) {
                    Button("초기화", role: .destructive) {
                        AppDataResetter.resetLocalData()
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("이 작업은 되돌릴 수 없습니다.\n로컬에 저장된 데이터가 삭제됩니다.")
                }
            }
        }
        .scrollDisabled(true)
        .navigationTitle("마이페이지")
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}

// MARK: - Permission Status

private enum LocationPermissionStatus {
    case notDetermined
    case denied
    case restricted
    case authorizedWhenInUse
    case authorizedAlways
    case unknown

    static var current: LocationPermissionStatus {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .unknown
        }
    }

    var displayText: String {
        switch self {
        case .notDetermined:
            return "미설정"
        case .denied:
            return "거부됨"
        case .restricted:
            return "제한됨"
        case .authorizedWhenInUse:
            return "허용됨(사용 중)"
        case .authorizedAlways:
            return "허용됨(항상)"
        case .unknown:
            return "알 수 없음"
        }
    }

    var kind: PermissionStatusRow.StatusKind {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways:
            return .good
        case .notDetermined:
            return .warning
        case .denied, .restricted:
            return .bad
        case .unknown:
            return .unknown
        }
    }
}

// MARK: - Data Reset

private enum AppDataResetter {
    static func resetLocalData() {
        // 1) UserDefaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            UserDefaults.standard.synchronize()
        }

        // 2) URLCache (이미지/응답 캐시 등)
        URLCache.shared.removeAllCachedResponses()

        // 3) SwiftData
        // TODO: - SwiftData 초기화
    }
}

// MARK: - Placeholder Destinations

private struct TermsOfServiceView: View {
    var body: some View {
        Text("이용약관 화면")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}

private struct PrivacyPolicyView: View {
    var body: some View {
        Text("개인정보처리방침 화면")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}

private struct OpenSourceLicensesView: View {
    var body: some View {
        Text("오픈소스 라이선스 화면")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}
