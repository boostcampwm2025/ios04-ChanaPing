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

        case userDidInteractMap
        case followUserRequested

        case cameraDidIdle(Coordinate, BoundingBox, MapCameraSnapshot)
        case cameraChangedByLocation(Coordinate, BoundingBox, MapCameraSnapshot)
        case cameraMoveConsumed

        case tapSearch
        case dismissPlaceSearch
        case selectPlace(Place)

        case dismissAddMessage

        case updateMessages([Message])

        case tapNoPlaceMarker([Message])
        case tapPlaceMarker([Message])
        case dismissPlaceCarousel

        case dismissTimelineView
        case tapNetworkRefresh
        case setToast(String?)
    }

    enum Action {
        case setCameraCoordinate(Coordinate)
        case setFollowingUser(Bool)
        case setCameraMoveTarget(MapCameraMoveCommand?)
        case setCameraSnapshot(MapCameraSnapshot?)

        case presentPlaceSearch(Bool)

        case setShowAddMessage(Bool)
        case setMessages([Message])

        case setSelectedNoPlace([Message])
        case setCarouselItems([PlaceCarouselDisplayModel])

        case setLoading(Bool)
        case setNetworkConnected(Bool)
        case setError(String)
        case setToastMessage(String?)
    }

    struct State {
        var messages: [Message] = []
        var cameraSnapshot: MapCameraSnapshot?

        var cameraCoordinate: Coordinate?
        var isFollowingUser: Bool = true

        var isPlaceSearchPresented: Bool = false
        var cameraMoveTarget: MapCameraMoveCommand?

        var isShowingAddMessage: Bool = false

        var selectedNoPlaceMessages: [Message] = []
        var carouselItems: [PlaceCarouselDisplayModel] = []

        var isLoading: Bool = false
        var isNetworkConnected = true
        var errorMessage: String = ""
        var toastMessage: String?
    }

    @Published var state: State

    private let debounceInterval: UInt64 = 300_000_000 // 300ms

    private var getNearbyMessageTask: Task<Void, Never>?
    private let getNearbyMessagesUseCase: GetNearbyMessagesUseCase
    private let networkMonitor: NetworkMonitor

    init(
        getNearbyMessagesUseCase: GetNearbyMessagesUseCase,
        networkMonitor: NetworkMonitor
    ) {
        self.state = State()
        self.getNearbyMessagesUseCase = getNearbyMessagesUseCase
        self.networkMonitor = networkMonitor
    }

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

                continuation.finish()

            case .userLocationReady(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))

                if state.isFollowingUser {
                    continuation.yield(
                        .setCameraMoveTarget(
                            .init(snapshot: .init(coordinate: coordinate), reason: .restore)
                        )
                    )
                }

                continuation.finish()

            case .onDisappear:
                self.getNearbyMessageTask?.cancel()
                self.getNearbyMessageTask = nil
                continuation.yield(.setLoading(false))
                continuation.finish()

            case .userDidInteractMap:
                continuation.yield(.setFollowingUser(false))
                continuation.finish()

            case .followUserRequested:
                continuation.yield(.setFollowingUser(true))
                continuation.finish()

            case .cameraDidIdle(let coordinate, let boundingBox, let snapshot):
                continuation.yield(.setCameraCoordinate(coordinate))
                continuation.yield(.setCameraSnapshot(snapshot))
                self.getNearbyMessages(
                    at: coordinate,
                    bounds: boundingBox,
                    continuation: continuation
                )

            case .cameraChangedByLocation(let coordinate, let boundingBox, let snapshot):
                continuation.yield(.setCameraCoordinate(coordinate))
                continuation.yield(.setCameraSnapshot(snapshot))
                self.getNearbyMessages(
                    at: coordinate,
                    bounds: boundingBox,
                    continuation: continuation
                )

            case .cameraMoveConsumed:
                continuation.yield(.setCameraMoveTarget(nil))
                continuation.yield(.presentPlaceSearch(false))
                continuation.finish()

            case .tapSearch:
                continuation.yield(.presentPlaceSearch(true))
                continuation.finish()

            case .dismissPlaceSearch:
                continuation.yield(.presentPlaceSearch(false))
                continuation.finish()

            case .selectPlace(let place):
                let target = MapCameraMoveCommand(
                    snapshot: .init(coordinate: place.coordinate),
                    reason: .userAction
                )
                continuation.yield(.setCameraMoveTarget(target))
                continuation.finish()

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))
                continuation.finish()

            case .updateMessages(let messages):
                continuation.yield(.setMessages(messages))
                continuation.finish()

            case .tapNoPlaceMarker(let messages):
                continuation.yield(.setSelectedNoPlace(messages))
                continuation.finish()

            case .tapPlaceMarker(let messages):
                let items = self.groupMessagesByPlace(messages)
                continuation.yield(.setCarouselItems(items))
                continuation.finish()

            case .dismissPlaceCarousel:
                continuation.yield(.setCarouselItems([]))
                continuation.finish()

            case .dismissTimelineView:
                continuation.yield(.setSelectedNoPlace([]))
                continuation.finish()

            case .tapNetworkRefresh:
                let isConnected = networkMonitor.checkConnection()
                continuation.yield(.setNetworkConnected(isConnected))
                continuation.finish()

            case .setToast(let message):
                continuation.yield(.setToastMessage(message))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setMessages(let messages):
            newState.messages = messages

        case .setCameraCoordinate(let coordinate):
            newState.cameraCoordinate = coordinate

        case .setFollowingUser(let isFollowing):
            newState.isFollowingUser = isFollowing

        case .setCameraSnapshot(let snapshot):
            newState.cameraSnapshot = snapshot

        case .setCameraMoveTarget(let snapshot):
            newState.cameraMoveTarget = snapshot

        case .presentPlaceSearch(let isPresented):
            newState.isPlaceSearchPresented = isPresented

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown

        case .setSelectedNoPlace(let messages):
            newState.selectedNoPlaceMessages = messages

        case .setCarouselItems(let items):
            newState.carouselItems = items

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
        continuation: AsyncStream<Action>.Continuation
    ) {
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
}

private extension MapStore {
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
