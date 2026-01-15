//
//  LocationProvider.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import CoreLocation
import Combine

@MainActor
final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var current: Coordinate?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    // one-shot 대기자 (공간 화면에서 작성 버튼 탭 시 사용)
    private var oneShotContinuations: [CheckedContinuation<Coordinate, Error>] = []
    private var isRequestingOneShot = false

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

    // 지도 화면: 지속 추적 시작
    func startContinuous() {
        guard manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways else {
            requestAuthorizationIfNeeded()
            return
        }
        manager.startUpdatingLocation()
    }

    // 지도 화면: 지속 추적 종료
    func stopContinuous() {
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
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        isRequestingOneShot = false

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
