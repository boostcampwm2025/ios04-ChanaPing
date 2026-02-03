//
//  LocationProvider.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import CoreLocation
import Combine

final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var current: Coordinate?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    // 앱 단위 정책에서 연속 추적을 요청했는지 여부
    private var wantsContinuousUpdates = false
    // 연속 추적이 이미 시작된 상태인지 여부(멱등성)
    private var isContinuousUpdating = false

    // one-shot 대기자 (공간 화면에서 작성 버튼 탭 시 사용)
    private var oneShotContinuations: [CheckedContinuation<Coordinate, Error>] = []
    private var isRequestingOneShot = false

    // 위치 권한 허용 여부
    var hasAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            AppLog.info("requestWhenInUseAuthorization()", category: .permission)
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            AppLog.debug("authorized -> requestLocation() for warm-up", category: .location)
            manager.requestLocation()

        case .denied, .restricted:
            AppLog.error("위치 권한이 거부/제한되어 있어 현재 위치로 이동할 수 없습니다.", category: .permission)

        @unknown default:
            break
        }
    }

    // 연속 추적 시작(앱 단위 정책)
    func startContinuous() {
        wantsContinuousUpdates = true

        guard manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways else {
            requestAuthorizationIfNeeded()
            return
        }

        guard isContinuousUpdating == false else {
            AppLog.debug("startContinuous() skipped (already updating)", category: .location)
            return
        }

        isContinuousUpdating = true
        AppLog.debug("startUpdatingLocation()", category: .location)
        manager.startUpdatingLocation()
    }

    // 연속 추적 종료(앱 단위 정책)
    func stopContinuous() {
        wantsContinuousUpdates = false

        guard isContinuousUpdating else {
            AppLog.debug("stopContinuous() skipped (not updating)", category: .location)
            return
        }

        isContinuousUpdating = false
        AppLog.debug("stopUpdatingLocation()", category: .location)
        manager.stopUpdatingLocation()
    }

    // 공간 화면: 작성 버튼 탭 시점의 최신 좌표 one-shot으로 받기
    func requestCurrentOnce() async throws -> Coordinate {
        // 권한 상태가 거부면 에러
        guard manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            oneShotContinuations.append(continuation)

            // 이미 one-shot 요청 중이면 합류만 하고 종료
            if isRequestingOneShot {
                AppLog.debug(
                    "one-shot location request joined (already requesting)",
                    category: .location
                )
                return
            }

            isRequestingOneShot = true
            AppLog.debug("requestLocation() one-shot", category: .location)
            manager.requestLocation()
        }
    }

    enum LocationError: Error {
        case notAuthorized
        case noLocation
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus

        // 권한이 허용으로 바뀌면 current warm-up
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

            // startContinuous()가 권한 요청으로 인해 대기 중이었다면, 권한 허용 즉시 연속 추적을 시작
            if wantsContinuousUpdates {
                startContinuous()
            }

        case .denied, .restricted:
            handleAuthorizationRevoked()

        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        isRequestingOneShot = false

        if wantsContinuousUpdates {
            isContinuousUpdating = true
        }

        guard let last = locations.last else {
            failOneShots(LocationError.noLocation)
            return
        }

        let coordinate = Coordinate(latitude: last.coordinate.latitude,
                                    longitude: last.coordinate.longitude)
        current = coordinate
        succeedOneShots(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequestingOneShot = false

        AppLog.error(
            "위치 업데이트 실패",
            category: .location,
            error: error
        )

        failOneShots(error)
    }

    private func handleAuthorizationRevoked() {
        // 마지막 위치를 UI에 남길지 여부는 정책 선택
        current = nil

        // 연속 추적 중이면 중단
        if isContinuousUpdating {
            AppLog.debug("authorization revoked -> stopUpdatingLocation()", category: .location)
            manager.stopUpdatingLocation()
        }
        isContinuousUpdating = false

        // one-shot 대기자 정리
        isRequestingOneShot = false
        failOneShots(LocationError.notAuthorized)
    }

    private func succeedOneShots(_ coordinate: Coordinate) {
        guard !oneShotContinuations.isEmpty else { return }
        let continuations = oneShotContinuations
        oneShotContinuations.removeAll()
        continuations.forEach { $0.resume(returning: coordinate) }
    }

    private func failOneShots(_ error: Error) {
        guard !oneShotContinuations.isEmpty else { return }
        let continuations = oneShotContinuations
        oneShotContinuations.removeAll()
        continuations.forEach { $0.resume(throwing: error) }
    }
}
