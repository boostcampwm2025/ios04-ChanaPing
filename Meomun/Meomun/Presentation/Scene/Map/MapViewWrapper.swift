//
//  MapViewWrapper.swift
//  Meomun
//
//  Created by Hayeon Park on 2/3/26.
//

import SwiftUI

struct MapViewWrapper: UIViewControllerRepresentable {
    private let messages: [Message]
    private let userLocation: Coordinate?
    private let cameraMoveTarget: MapCameraMoveCommand?
    private let onCameraMoveConsumed: () -> Void
    private let onTapPlace: (([Message]) -> Void)?
    private let onTapNoPlace: (([Message]) -> Void)?
    private let onUserGesture: (() -> Void)?
    private let onFollowRequested: (() -> Void)?
    private let onCameraIdle: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)?
    private let onCameraChangedByLocation: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)?
    private let onFirstMapIdle: (() -> Void)?

    private let messageMarkerManager: MessageMarkerManager
    private let isFollowingUser: Bool
    private let isTiltOn: Bool

    init(
        userLocation: Coordinate?,
        isFollowingUser: Bool,
        isTiltOn: Bool,
        markerManager: MessageMarkerManager,
        messages: [Message],
        cameraMoveTarget: MapCameraMoveCommand?,
        onCameraMoveConsumed: @escaping () -> Void,
        onTapPlace: (([Message]) -> Void)? = nil,
        onTapNoPlace: (([Message]) -> Void)? = nil,
        onUserGesture: (() -> Void)?,
        onFollowRequested: (() -> Void)?,
        onCameraIdle: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)? = nil,
        onCameraChangedByLocation: ((Coordinate, BoundingBox, MapCameraSnapshot) -> Void)? = nil,
        onFirstMapIdle: (() -> Void)? = nil
    ) {
        self.userLocation = userLocation
        self.isFollowingUser = isFollowingUser
        self.isTiltOn = isTiltOn
        self.messageMarkerManager = markerManager
        self.messages = messages
        self.cameraMoveTarget = cameraMoveTarget
        self.onCameraMoveConsumed = onCameraMoveConsumed
        self.onTapPlace = onTapPlace
        self.onTapNoPlace = onTapNoPlace
        self.onUserGesture = onUserGesture
        self.onFollowRequested = onFollowRequested
        self.onCameraIdle = onCameraIdle
        self.onCameraChangedByLocation = onCameraChangedByLocation
        self.onFirstMapIdle = onFirstMapIdle
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastMessagesSnapshot: Int?
        var lastCameraMoveTarget: MapCameraMoveCommand?
        var didInitialLoad = false

        var lastUserLocation: Coordinate?
        var lastIsFollowingUser: Bool?
    }

    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController(
            messageMarkerManager: messageMarkerManager,
            onTapPlace: onTapPlace,
            onTapNoPlace: onTapNoPlace,
            onUserGesture: onUserGesture,
            onFollowRequested: onFollowRequested,
            onCameraIdle: onCameraIdle,
            onCameraChangedByLocation: onCameraChangedByLocation
        )

        viewController.onFirstMapIdle = onFirstMapIdle
        viewController.loadViewIfNeeded()

        // 초기 1회 loadMessages() 호출
        viewController.loadMessages(messages)
        viewController.updateUserLocation(userLocation)

        context.coordinator.lastMessagesSnapshot = messagesSnapshot(messages)
        context.coordinator.didInitialLoad = true
        context.coordinator.lastUserLocation = userLocation
        context.coordinator.lastIsFollowingUser = isFollowingUser

        return viewController
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // 1) following 상태 변경 diff
        let prevFollowing = context.coordinator.lastIsFollowingUser
        let didFollowingChange = (prevFollowing != isFollowingUser)

        if didFollowingChange {
            uiViewController.setFollowingUser(isFollowingUser)
        }

        // 2) 틸트는 바뀔 때만
        uiViewController.setTiltEnabled(isTiltOn, animated: true)

        // 3) 위치 업데이트 diff
        let didUserLocationChange: Bool = {
            guard let new = userLocation else {
                return context.coordinator.lastUserLocation != nil
            }
            guard let old = context.coordinator.lastUserLocation else { return true }

            // Coordinate가 Equatable이면 그냥 new != old
            // 아니면 오차 허용 비교 (GPS 튐 방지)
            return abs(new.latitude - old.latitude) > 0.000001
            || abs(new.longitude - old.longitude) > 0.000001
        }()

        if didUserLocationChange || didFollowingChange {
            context.coordinator.lastUserLocation = userLocation

            // 추적 상태에 따라 위치 반영
            if isFollowingUser {
                uiViewController.updateUserLocation(userLocation)
            } else {
                // 추적 해제 모드 시 파란점만 유지하고 카메라는 안 움직이도록 설정
                uiViewController.updateUserLocationOverlayOnly(userLocation)
            }
        }

        context.coordinator.lastIsFollowingUser = isFollowingUser

        // 4) cameraMoveTarget diff
        if let target = cameraMoveTarget, context.coordinator.lastCameraMoveTarget != target {
            // 동일 target인 경우 호출 X
            context.coordinator.lastCameraMoveTarget = target
            uiViewController.moveCamera(
                to: target.snapshot,
                animated: target.reason == .userAction
            )

            DispatchQueue.main.async {
                onCameraMoveConsumed()
            }
        }

        // 5) messages diff
        let snap = messagesSnapshot(messages)

        // 동일 메시지인 경우 loadMessages() 호출 X
        guard context.coordinator.lastMessagesSnapshot != snap else { return }

        context.coordinator.lastMessagesSnapshot = snap
        uiViewController.loadMessages(messages)
    }

    private func messagesSnapshot(_ messages: [Message]) -> Int {
        var hasher = Hasher()

        for message in messages {
            hasher.combine(message.id)
        }

        return hasher.finalize()
    }
}
