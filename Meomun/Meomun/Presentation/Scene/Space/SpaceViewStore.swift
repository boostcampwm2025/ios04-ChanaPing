//
//  SpaceViewStore.swift
//  Meomun
//
//  Created by MinwooJe on 1/8/26.
//

import Combine
import Foundation

final class SpaceViewStore: Store {

    // MARK: - Intent / Action / State

    enum Intent {
        case onAppear(placeID: PlaceID)
    }

    enum Action {
        case setLoading(Bool)
        case setMessages([Message])
        case setError(String)
        case setCurrentPlaceID(PlaceID)
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
        var messages: [Message] = []
        var currentPlaceID: PlaceID?
    }

    @Published var state: State = .init()

    private let fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase

    private var fetchMessagesTask: Task<Void, Never>?

    init(fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase) {
        self.fetchPlaceMessagesUseCase = fetchPlaceMessagesUseCase
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let placeID):
                continuation.yield(.setCurrentPlaceID(placeID))
                fetchMessages(for: placeID, continuation: continuation)
            }
        }
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

                guard !Task.isCancelled else { return}

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

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setMessages(let messages):
            newState.messages = messages

        case .setError(let message):
            newState.errorMessage = message

        case .setCurrentPlaceID(let placeID):
            newState.currentPlaceID = placeID
        }

        return newState
    }

}
