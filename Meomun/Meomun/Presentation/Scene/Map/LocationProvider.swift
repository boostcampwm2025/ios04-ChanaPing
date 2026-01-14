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

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()

        case .denied, .restricted:
            AppLog.error("위치 권한이 거부/제한되어 있어 현재 위치로 이동할 수 없습니다.", category: .permission)

        @unknown default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        requestAuthorizationIfNeeded()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let last = locations.last else { return }

        current = Coordinate(
            latitude: last.coordinate.latitude,
            longitude: last.coordinate.longitude
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLog.error(
            "위치 업데이트 실패",
            category: .location,
            error: error
        )
    }
}
