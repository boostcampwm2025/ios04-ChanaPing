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
        case cameraDidIdle(Coordinate)
        case cameraChangedByLocation(Coordinate)
        case tapWriteButton
        case dismissAddMessage
        case updateMessages([Message])

        case tapPlaceMarker(Place)
        case dismissSpaceView

        case tapNoPlaceMarker([Message])
        case dismissTimelineView

        case setToast(String?)
    }

    enum Action {
        case setCameraCoordinate(Coordinate)
        case setShowAddMessage(Bool)
        case setMessages([Message])
        case setSelectedPlace(Place?)
        case setSelectedNoPlace([Message])
        case setLoading(Bool)
        case setError(String)
        case setToastMessage(String?)
    }

    struct State {
        var messages: [Message] = []
        var cameraCoordinate: Coordinate?
        var isShowingAddMessage: Bool = false
        var selectedPlace: Place?
        var selectedNoPlaceMessages: [Message] = []
        var isLoading: Bool = false
        var errorMessage: String = ""
        var toastMessage: String?
    }

    @Published var state: State

    private let debounceInterval: UInt64 = 300_000_000 // 300ms

    private var getNearbyMessageTask: Task<Void, Never>?
    private let getNearbyMessagesUseCase: GetNearbyMessagesUseCase

    init(
        getNearbyMessagesUseCase: GetNearbyMessagesUseCase
    ) {
        self.state = State()
        self.getNearbyMessagesUseCase = getNearbyMessagesUseCase
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))
                self.getNearbyMessages(at: coordinate, continuation: continuation)

            case .onDisappear:
                self.getNearbyMessageTask?.cancel()
                self.getNearbyMessageTask = nil
                continuation.yield(.setLoading(false))
                continuation.finish()

            case .cameraDidIdle(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))
                self.getNearbyMessages(at: coordinate, continuation: continuation)

            case .cameraChangedByLocation(let coordinate):
                continuation.yield(.setCameraCoordinate(coordinate))
                self.getNearbyMessages(at: coordinate, continuation: continuation)

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

            case .tapNoPlaceMarker(let messages):
                continuation.yield(.setSelectedNoPlace(messages))
                continuation.finish()

            case .dismissTimelineView:
                continuation.yield(.setSelectedNoPlace([]))
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

        case .setShowAddMessage(let isShown):
            newState.isShowingAddMessage = isShown

        case .setSelectedPlace(let place):
            newState.selectedPlace = place

        case .setSelectedNoPlace(let messages):
            newState.selectedNoPlaceMessages = messages

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let message):
            newState.errorMessage = message

        case .setToastMessage(let message):
            newState.toastMessage = message
        }

        return newState
    }

    private func getNearbyMessages(
        at coordinate: Coordinate,
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
//                let messages = try await self.getNearbyMessagesUseCase.execute(
//                    location: coordinate,
//                    limit: nil
//                )

                let messages = self.getDummyMessages()

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
