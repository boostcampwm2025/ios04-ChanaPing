//
//  PlaceSearchStore.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

import Combine
import Foundation

final class PlaceSearchStore: Store {

    enum Phase: Equatable {
        case idle
        case loading
        case loaded([Place])
        case empty
        case failed(String)

        var results: [Place] {
            switch self {
            case .loaded(let places):
                return places
            default:
                return []
            }
        }
    }

    enum Intent {
        case queryChanged(String)
        case submit
        case tapResult(Place)
        case dismiss
    }

    enum Action {
        case setQuery(String)
        case setPhase(Phase)
        case clear
    }

    struct State {
        var query: String = ""
        var phase: Phase = .idle
        var userLocation: Coordinate?
    }

    @Published var state: State

    // 검색 작업이 결과를 반환
    private var searchTask: Task<[Place], Never>?

    private let searchNearbyPlaces: SearchNearbyPlaceUseCase
    private let radiusMeters: Double

    private let onSelect: (Place) -> Void
    private let onDismiss: () -> Void

    init(
        searchPlaces: SearchNearbyPlaceUseCase,
        userLocation: Coordinate?,
        radiusMeters: Double = 60,
        onSelect: @escaping (Place) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.searchNearbyPlaces = searchPlaces
        self.state = State(userLocation: userLocation)
        self.radiusMeters = radiusMeters
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .queryChanged(let query):
                continuation.yield(.setQuery(query))
                search(for: query)

            case .submit:
                search(for: state.query, immediate: true)

            case .tapResult(let place):
                onSelect(place)

            case .dismiss:
                cancelSearch()
                onDismiss()
            }

            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setQuery(let query):
            newState.query = query

        case .setPhase(let phase):
            newState.phase = phase

        case .clear:
            newState.query = ""
            newState.phase = .idle
        }

        return newState
    }

    @MainActor
    private func apply(_ action: Action) {
        state = reduce(state: state, action: action)
    }

    private func search(for query: String, immediate: Bool = false) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        cancelSearch()

        guard !trimmedQuery.isEmpty else {
            Task { @MainActor in
                apply(.setPhase(.idle))
            }
            return
        }

        let stabilizedQuery = trimmedQuery
        let userLocation = self.state.userLocation
        let radiusMeters = self.radiusMeters
        let useCase = self.searchNearbyPlaces

        searchTask = Task { [weak self] in
            guard let self, let userLocation else { return [] }

            if !immediate {
                // 디바운스 300ms
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            if Task.isCancelled { return [] }

            do {
                let results = try await useCase.execute(
                    query: stabilizedQuery,
                    userLocation: userLocation,
                    radiusMeters: radiusMeters
                )
                return results
            } catch {
                await self.handleSearchError(error)
                return []
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.apply(.setPhase(.loading))
        }

        Task { @MainActor [weak self] in
            guard let self, let task = self.searchTask else { return }
            let results = await task.value
            if Task.isCancelled { return }

            await MainActor.run {
                switch self.state.phase {
                case .failed:
                    return
                default:
                    let nextPhase: Phase = results.isEmpty ? .empty : .loaded(results)
                    self.apply(.setPhase(nextPhase))
                }
            }
        }
    }

    @MainActor
    private func handleSearchError(_ error: Error) {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            AppLog.debug("Search cancelled", category: .store)
            return
        }

        if case let NetworkError.serverError(statusCode, data) = error {
            AppLog.error(
                "LocalSearch server error",
                category: .network,
                error: error
            )

            if let data,
               let body = String(data: data, encoding: .utf8) {
                AppLog.debug(
                    "Response body: \(body)",
                    category: .network
                )
            }

            apply(.setPhase(.failed("검색 중 오류가 발생했습니다. (\(statusCode))")))
        } else {
            AppLog.error(
                "LocalSearch unknown error",
                category: .network,
                error: error
            )

            apply(.setPhase(.failed("검색 중 오류가 발생했습니다.")))
        }
    }

    private func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
