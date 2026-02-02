//
//  SettingView.swift
//  Meomun
//
//  Created by hoon on 1/28/26.
//

import CoreLocation
import NMapsMap
import SwiftUI

struct SettingView: View {
    @StateObject private var store: SettingStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.setTabBarHidden) private var setTabBarHidden
    @Environment(\.setNavBarHidden) private var setNavBarHidden
    @State private var permissionStatus = LocationPermissionStatus.current

    private let mapView: NMFMapView = .init()

    init(store: SettingStore) {
        _store = .init(wrappedValue: store)
    }

    var body: some View {
        VStack {
            Color.clear.frame(height: ShellLayout.topInset)
            List {
                // 정보
                Section("정보") {
                    AppVersionRow()

                    NavigationRow(title: "이용약관") {
                        TermsOfServiceView()
                            .onAppear {
                                setTabBarHidden(true)
                                setNavBarHidden(true)
                            }
                    }

                    NavigationRow(title: "개인정보처리방침") {
                        PrivacyPolicyView()
                            .onAppear {
                                setTabBarHidden(true)
                                setNavBarHidden(true)
                            }
                    }

                    NavigationRow(title: "오픈소스 라이선스") {
                        OpenSourceLicensesView()
                            .onAppear {
                                setTabBarHidden(true)
                                setNavBarHidden(true)
                            }
                    }

                    ActionRow(title: "네이버 지도 법적 공지") {
                        mapView.showLegalNotice()
                    }

                    ActionRow(title: "네이버 지도 오픈소스 라이선스") {
                        mapView.showOpenSourceLicense()
                    }
                }
                .listRowBackground(Color.mmContainerBackground)

                // 권한
                Section("권한") {
                    PermissionStatusRow(
                        title: "위치 권한",
                        status: permissionStatus.displayText,
                        statusKind: permissionStatus.kind
                    )

                    Button("앱 설정으로 이동") {
                        Task { await store.send(intent: .tapOpenAppSettings) }
                    }
                }
                .listRowBackground(Color.mmContainerBackground)

                // 데이터
                Section("데이터") {
                    Button(role: .destructive) {
                        Task { await store.send(intent: .tapResetAppData) }
                    } label: {
                        Text("앱 데이터 초기화")
                    }
                    .mmAlert(
                        resetAlertBinding,
                        title: { $0.title },
                        message: { $0.message },
                        buttons: { $0.buttons }
                    )

                    Text("앱 데이터 초기화 시 모든 로컬 데이터가 삭제되며, 이 작업은 되돌릴 수 없습니다.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.mmContainerBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.mmBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 100)
        }
        .onAppear {
            permissionStatus = LocationPermissionStatus.current
            setTabBarHidden(false)
            setNavBarHidden(false)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                permissionStatus = LocationPermissionStatus.current
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingView(
            store: .init(
                appSettingsOpener: AppSettingsOpener(),
                resetMessagesUseCase: ResetMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                )
            )
        )
    }
}

// MARK: - Alert

private extension SettingView {
    var resetAlertBinding: Binding<MMAlertModel?> {
        Binding(
            get: { store.state.resetAlert },
            set: { newValue in
                if newValue == nil {
                    Task { await store.send(intent: .dismissResetAlert) }
                }
            }
        )
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

// MARK: - Placeholder Destinations

private struct TermsOfServiceView: View {
    var body: some View {
        Text("이용약관 화면")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.mmBackground))
    }
}

private struct OpenSourceLicensesView: View {
    var body: some View {
        Text("오픈소스 라이선스 화면")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.mmBackground))
    }
}
