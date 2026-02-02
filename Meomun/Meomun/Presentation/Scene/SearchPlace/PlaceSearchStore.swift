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

    private let onSelect: (Place) -> Void
    private let onDismiss: () -> Void

    init(
        searchPlaces: SearchNearbyPlaceUseCase,
        userLocation: Coordinate?,
        onSelect: @escaping (Place) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.searchNearbyPlaces = searchPlaces
        self.state = State(userLocation: userLocation)
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
}

private extension PlaceSearchStore {

    // MARK: - 검색

    func search(for query: String, immediate: Bool = false) {
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
        let useCase = self.searchNearbyPlaces

        // 페이지네이션 초기화
        Task { @MainActor in
            apply(.setPhase(.loading))
        }

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
                    userLocation: userLocation
                )
                return results
            } catch {
                await self.handleSearchError(error)
                return []
            }
        }

        Task { @MainActor [weak self] in
            guard let self, let task = self.searchTask else { return }
            let results = await task.value
            if Task.isCancelled { return }

            var seen = Set<PlaceID>()
            let deduped = results.filter { seen.insert($0.id).inserted }

            let nextPhase: Phase = deduped.isEmpty ? .empty : .loaded(deduped)
            apply(.setPhase(nextPhase))
        }
    }

    @MainActor
    func handleSearchError(_ error: Error) {
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
        } else if case NetworkError.noConnection = error {
            apply(.setPhase(.failed("네트워크 연결을 확인해주세요.")))
        } else {
            AppLog.error(
                "LocalSearch unknown error",
                category: .network,
                error: error
            )

            apply(.setPhase(.failed("검색 중 오류가 발생했습니다.")))
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
