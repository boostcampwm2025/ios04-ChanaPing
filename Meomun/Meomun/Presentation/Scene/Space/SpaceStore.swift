//
//  SpaceViewStore.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import Combine
import Foundation

final class SpaceStore: Store {

    enum Intent {
        case onAppear(placeID: PlaceID)
        case setToast(String?)
    }

    enum Action {
        case setLoading(Bool)
        case setMessages([Message])
        case setError(String)
        case setUserLocation(Coordinate)
        case setCurrentPlaceID(PlaceID)
        case setToastMessage(String?)
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
        var messages: [Message] = []
        var userLocation: Coordinate?           // TODO: - 지도 > 공간 진입 시점 좌표 넘겨주고, 옵셔널 지우기
        var currentPlaceID: PlaceID?
        var toastMessage: String?
    }

    @Published var state: State

    private let locationProvider: LocationProvider
    private var oneShotTask: Task<Void, Never>?

    private let fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase

    private var fetchMessagesTask: Task<Void, Never>?

    private let place: Place

    init(
        locationProvider: LocationProvider,
        fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase,
        place: Place
    ) {
        self.locationProvider = locationProvider
        self.state = State()
        self.fetchPlaceMessagesUseCase = fetchPlaceMessagesUseCase
        self.place = place
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let placeID):
                continuation.yield(.setCurrentPlaceID(placeID))
                fetchMessages(for: placeID, continuation: continuation)

            case .setToast(let message):
                continuation.yield(.setToastMessage(message))
                continuation.finish()
            }
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setMessages(let messages):
            newState.messages = messages

        case .setError(let message):
            newState.errorMessage = message

        case .setUserLocation(let location):
            newState.userLocation = location

        case .setCurrentPlaceID(let placeID):
            newState.currentPlaceID = placeID

        case .setToastMessage(let message):
            newState.toastMessage = message
        }

        return newState
    }

    private func fetchMessages(
        for placeID: PlaceID,
        continuation: AsyncStream<Action>.Continuation
    ) {
        fetchMessagesTask?.cancel()
        continuation.yield(.setLoading(true))

        fetchMessagesTask = Task {
            defer {
                continuation.yield(.setLoading(false))
                continuation.finish()
            }

            do {
                let messages = try await fetchPlaceMessagesUseCase.execute(placeID: placeID)

                guard !Task.isCancelled else { return }

                continuation.yield(.setMessages(messages))
                continuation.yield(.setError(""))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                continuation.yield(.setError(error.localizedDescription))
            }
        }
    }
}
