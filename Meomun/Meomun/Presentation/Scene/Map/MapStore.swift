//
//  MapStore.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation
import Combine

final class MapStore: Store {
    enum Intent {
        case onAppear(Coordinate)
        case userLocationReady(Coordinate)
        case onDisappear

        case tapTiltToggle

        case userDidInteractMap
        case followUserRequested

        case cameraDidIdle(Coordinate, BoundingBox, MapCameraSnapshot)
        case cameraChangedByLocation(Coordinate, BoundingBox, MapCameraSnapshot)
        case cameraMoveConsumed

        case refreshVisibleMessages

        case tapSearch
        case dismissPlaceSearch
        case selectPlace(Place)

        case tapCarouselPlace(Place)

        case dismissSpace

        case dismissAddMessage

        case tapNoPlaceMarker([Message])
        case tapPlaceMarker([Message])
        case dismissPlaceCarousel

        case dismissTimelineView
        case tapNetworkRefresh
        case setToast(String?)
    }

    enum Action {
        case setHasAnyMessage(Bool)

        case setCameraCoordinate(Coordinate)
        case setFollowingUser(Bool)
        case setCameraMoveTarget(MapCameraMoveCommand?)
        case setCameraSnapshot(MapCameraSnapshot?)
        case setCameraBounds(BoundingBox)
        case setDidApplyResolvedUserLocation(Bool)

        case presentPlaceSearch(Bool)

        case setTiltOn(Bool)

        case setShowAddMessage(Bool)
        case setMessages([Message])

        case setSelectedNoPlace([Message])
        case setCarouselItems([PlaceCarouselDisplayModel])

        case setSelectedPlaceForSpace(Place?)

        case setLoading(Bool)
        case setNetworkConnected(Bool)
        case setError(String)
        case setToastMessage(String?)
    }

    struct State {
        var messages: [Message] = []
        var hasAnyMessage: Bool = false
        var cameraSnapshot: MapCameraSnapshot?

        var cameraCoordinate: Coordinate?
        var cameraBounds: BoundingBox?
        var isFollowingUser: Bool = true

        var isPlaceSearchPresented: Bool = false
        var cameraMoveTarget: MapCameraMoveCommand?

        var isShowingAddMessage: Bool = false

        var selectedNoPlaceMessages: [Message] = []
        var carouselItems: [PlaceCarouselDisplayModel] = []

        var isTiltOn: Bool = true
        var selectedPlaceForSpace: Place?
        var didApplyResolvedUserLocation: Bool = false

        var isLoading: Bool = false
        var isNetworkConnected = true
        var errorMessage: String = ""
        var toastMessage: String?
    }

    @Published var state: State

    private let debounceInterval: UInt64 = 300_000_000 // 300ms
    private let prefetchRatio: Double = 0.2

    private var getNearbyMessageTask: Task<Void, Never>?
    private var lastFetchBounds: BoundingBox?
    private var lastFetchZoomBucket: Int?
    private let getNearbyMessagesUseCase: GetNearbyMessagesUseCase
    private let hasAnyMessageUseCase: HasAnyMessageUseCase
    private let networkMonitor: NetworkMonitoring

    init(
        getNearbyMessagesUseCase: GetNearbyMessagesUseCase,
        hasAnyMessageUseCase: HasAnyMessageUseCase,
        networkMonitor: NetworkMonitoring
    ) {
        self.state = State()
        self.getNearbyMessagesUseCase = getNearbyMessagesUseCase
        self.hasAnyMessageUseCase = hasAnyMessageUseCase
        self.networkMonitor = networkMonitor
    }

    // swiftlint:disable:next function_body_length
    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))

                let isConnected = networkMonitor.checkConnection()
                continuation.yield(.setNetworkConnected(isConnected))

                if let snapshot = state.cameraSnapshot {
                    continuation.yield(.setFollowingUser(false))
                    continuation.yield(.setCameraMoveTarget(.init(snapshot: snapshot, reason: .restore)))
                } else {
                    continuation.yield(.setFollowingUser(true))
                    continuation.yield(
                        .setCameraMoveTarget(
                            .init(snapshot: .init(coordinate: coordinate), reason: .restore)
                        )
                    )
                }

            case .userLocationReady(let coordinate):
                guard state.didApplyResolvedUserLocation == false else { break }

                continuation.yield(.setDidApplyResolvedUserLocation(true))
                continuation.yield(.setCameraCoordinate(coordinate))

                if state.isFollowingUser {
                    continuation.yield(
                        .setCameraMoveTarget(
                            .init(snapshot: .init(coordinate: coordinate), reason: .restore)
                        )
                    )
                }

            case .onDisappear:
                self.getNearbyMessageTask?.cancel()
                self.getNearbyMessageTask = nil
                self.lastFetchBounds = nil
                self.lastFetchZoomBucket = nil
                continuation.yield(.setLoading(false))

            case .tapTiltToggle:
                continuation.yield(.setTiltOn(!state.isTiltOn))

            case .userDidInteractMap:
                continuation.yield(.setFollowingUser(false))

            case .followUserRequested:
                continuation.yield(.setFollowingUser(true))

            case .cameraDidIdle(let coordinate, let boundingBox, let snapshot):
                continuation.yield(.setCameraCoordinate(coordinate))
                continuation.yield(.setCameraSnapshot(snapshot))
                continuation.yield(.setCameraBounds(boundingBox))
                self.getNearbyMessages(
                    at: coordinate,
                    bounds: boundingBox,
                    snapshot: snapshot,
                    continuation: continuation
                )
                self.refreshHasAnyMessage(continuation)
                return

            case .cameraChangedByLocation(let coordinate, let boundingBox, let snapshot):
                continuation.yield(.setCameraCoordinate(coordinate))
                continuation.yield(.setCameraSnapshot(snapshot))
                continuation.yield(.setCameraBounds(boundingBox))
                self.getNearbyMessages(
                    at: coordinate,
                    bounds: boundingBox,
                    snapshot: snapshot,
                    continuation: continuation
                )
                return

            case .cameraMoveConsumed:
                continuation.yield(.setCameraMoveTarget(nil))
                continuation.yield(.presentPlaceSearch(false))

            case .refreshVisibleMessages:
                guard let coordinate = state.cameraCoordinate,
                      let bounds = state.cameraBounds
                else {
                    continuation.finish()
                    return
                }
                let snapshot = state.cameraSnapshot ?? .init(coordinate: coordinate)

                self.getNearbyMessages(
                    at: coordinate,
                    bounds: bounds,
                    snapshot: snapshot,
                    force: true,
                    continuation: continuation
                )
                return

            case .tapSearch:
                continuation.yield(.presentPlaceSearch(true))

            case .dismissPlaceSearch:
                continuation.yield(.presentPlaceSearch(false))

            case .selectPlace(let place):
                let target = MapCameraMoveCommand(
                    snapshot: .init(coordinate: place.coordinate),
                    reason: .userAction
                )
                continuation.yield(.setCameraMoveTarget(target))

            case .tapCarouselPlace(let place):
                continuation.yield(.setSelectedPlaceForSpace(place))
                continuation.yield(.setCarouselItems([]))

            case .dismissSpace:
                continuation.yield(.setSelectedPlaceForSpace(nil))

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))

            case .tapNoPlaceMarker(let messages):
                continuation.yield(.setSelectedNoPlace(messages))

            case .tapPlaceMarker(let messages):
                let items = self.groupMessagesByPlace(messages)
                continuation.yield(.setCarouselItems(items))

            case .dismissPlaceCarousel:
                continuation.yield(.setCarouselItems([]))

            case .dismissTimelineView:
                continuation.yield(.setSelectedNoPlace([]))

            case .tapNetworkRefresh:
                let isConnected = networkMonitor.checkConnection()
                continuation.yield(.setNetworkConnected(isConnected))

            case .setToast(let message):
                continuation.yield(.setToastMessage(message))
            }
            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setHasAnyMessage(let value):
            newState.hasAnyMessage = value

        case .setMessages(let messages):
            newState.messages = messages

        case .setCameraCoordinate(let coordinate):
            newState.cameraCoordinate = coordinate

        case .setFollowingUser(let isFollowing):
            newState.isFollowingUser = isFollowing

        case .setCameraSnapshot(let snapshot):
            newState.cameraSnapshot = snapshot

        case .setCameraBounds(let bounds):
            newState.cameraBounds = bounds

        case .setDidApplyResolvedUserLocation(let value):
            newState.didApplyResolvedUserLocation = value

        case .setCameraMoveTarget(let snapshot):
            newState.cameraMoveTarget = snapshot

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .setTiltOn(let isTiltOn):
            newState.isTiltOn = isTiltOn

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown

        case .setSelectedNoPlace(let messages):
            newState.selectedNoPlaceMessages = messages

        case .setCarouselItems(let items):
            newState.carouselItems = items

        case .setSelectedPlaceForSpace(let place):
            newState.selectedPlaceForSpace = place

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setNetworkConnected(let isConnected):
            newState.isNetworkConnected = isConnected

        case .setError(let message):
            newState.errorMessage = message

        case .setToastMessage(let message):
            newState.toastMessage = message
        }

        return newState
    }

    private func getNearbyMessages(
        at coordinate: Coordinate,
        bounds: BoundingBox,
        snapshot: MapCameraSnapshot,
        force: Bool = false,
        continuation: AsyncStream<Action>.Continuation
    ) {
        if !force, shouldSkipFetch(
            coordinate: coordinate,
            bounds: bounds,
            snapshot: snapshot
        ) {
            getNearbyMessageTask?.cancel()
            getNearbyMessageTask = nil

            if state.isLoading {
                continuation.yield(.setLoading(false))
            }

            continuation.finish()
            return
        }

        getNearbyMessageTask?.cancel()

        getNearbyMessageTask = Task { [weak self] in
            defer {
                if !Task.isCancelled {
                    continuation.yield(.setLoading(false))
                }
                continuation.finish()
            }

            guard let self else { return }

            do {
                try await Task.sleep(nanoseconds: self.debounceInterval)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            continuation.yield(.setLoading(true))

            do {
                let messages = try await self.getNearbyMessagesUseCase.execute(
                    at: coordinate,
                    bounds: bounds,
                    limit: nil
                )

                guard !Task.isCancelled else { return }

                self.lastFetchBounds = bounds.expanded(by: self.prefetchRatio)
                self.lastFetchZoomBucket = self.zoomBucket(from: snapshot)

                continuation.yield(.setMessages(messages))
                continuation.yield(.setError(""))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                AppLog.error("Failed to fetch nearby messages", category: .store, error: error)
                continuation.yield(.setError(error.localizedDescription))
            }
        }
    }

    private func refreshHasAnyMessage(_ continuation: AsyncStream<Action>.Continuation? = nil) {
        Task { @MainActor in
            do {
                let hasAny = try await hasAnyMessageUseCase.execute()
                continuation?.yield(.setHasAnyMessage(hasAny))
            } catch {
                continuation?.yield(.setHasAnyMessage(false))
            }
        }
    }
}

private extension MapStore {
    func shouldSkipFetch(
        coordinate: Coordinate,
        bounds: BoundingBox,
        snapshot: MapCameraSnapshot
    ) -> Bool {
        guard let lastFetchBounds,
              let lastFetchZoomBucket
        else {
            return false
        }

        if lastFetchZoomBucket != zoomBucket(from: snapshot) {
            return false
        }

        return lastFetchBounds.contains(bounds)
    }

    func zoomBucket(from snapshot: MapCameraSnapshot) -> Int {
        Int(floor(snapshot.zoom))
    }

    /// 메시지 배열을 Place별로 그룹화하여 캐러셀 아이템 배열로 변환
    func groupMessagesByPlace(_ messages: [Message]) -> [PlaceCarouselDisplayModel] {
        var placeMessages: [Place: [Message]] = [:]

        for message in messages {
            guard let place = message.placeTag else { continue }
            placeMessages[place, default: []].append(message)
        }

        return placeMessages.map { place, messages in
            PlaceCarouselDisplayModel(place: place, messageCount: messages.count)
        }
        .sorted { $0.messageCount > $1.messageCount }
    }
}
