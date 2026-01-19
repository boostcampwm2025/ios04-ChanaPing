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
        case onDisappear
        case updateUserLocation(Coordinate)
        case tapWriteButton
        case dismissAddMessage
        case updateMessages([Message])
        case tapPlaceMarker(Place)
        case dismissSpaceView
    }

    enum Action {
        case setUserLocation(Coordinate)
        case setCameraCoordinate(Coordinate)
        case setShowAddMessage(Bool)
        case setMessages([Message])
        case setSelectedPlace(Place?)
        case setLoading(Bool)
        case setError(String)
    }

    struct State {
        var messages: [Message] = []
        var userLocation: Coordinate
        var cameraCoordinate: Coordinate?
        var isShowingAddMessage: Bool = false
        var selectedPlace: Place?
        var isLoading: Bool = false
        var errorMessage: String = ""
    }

    @Published var state: State

    private var messageStreamTask: Task<Void, Never>?
    private let getNearbyMessagesUseCase: GetNearbyMessagesUseCase

    init(
        userLocation: Coordinate,
        getNearbyMessagesUseCase: GetNearbyMessagesUseCase
    ) {
        self.state = State(userLocation: userLocation)
        self.getNearbyMessagesUseCase = getNearbyMessagesUseCase
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))
                self.fetchNearbyMessages(at: coordinate, continuation: continuation)

            case .onDisappear:
                // 화면 내려갈 때 실시간 작업 정리
                messageStreamTask?.cancel()
                messageStreamTask = nil
                continuation.finish()

            case .updateUserLocation(let location):
                continuation.yield(.setUserLocation(location))
                continuation.finish()

            case .tapWriteButton:
                continuation.yield(.setShowAddMessage(true))
                continuation.finish()

            case .dismissAddMessage:
                continuation.yield(.setShowAddMessage(false))
                continuation.finish()

            case .updateMessages(let messages):
                continuation.yield(.setMessages(messages))
                continuation.finish()

            case .tapPlaceMarker(let place):
                continuation.yield(.setSelectedPlace(place))
                continuation.finish()

            case .dismissSpaceView:
                continuation.yield(.setSelectedPlace(nil))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setMessages(let messages):
            newState.messages = messages

        case .setUserLocation(let location):
            newState.userLocation = location

        case .setCameraCoordinate(let coordinate):
            newState.cameraCoordinate = coordinate

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown

        case .setSelectedPlace(let place):
            newState.selectedPlace = place

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let message):
            newState.errorMessage = message
        }

        return newState
    }

    private func fetchNearbyMessages(continuation: AsyncStream<Action>.Continuation) {
    private func fetchNearbyMessages(
        at coordinate: Coordinate,
        continuation: AsyncStream<Action>.Continuation
    ) {
        messageStreamTask?.cancel()
        continuation.yield(.setLoading(true))

        messageStreamTask = Task { [weak self] in
            guard let self else { return }

            defer {
                continuation.yield(.setLoading(false))
                continuation.finish()
            }

            do {
                let messages = try await self.getNearbyMessagesUseCase.execute(
                    location: coordinate,
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
