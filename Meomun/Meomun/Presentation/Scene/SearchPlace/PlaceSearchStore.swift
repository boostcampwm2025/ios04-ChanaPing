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
        case scrollReachedBottom
        case tapResult(Place)
        case dismiss
    }

    enum Action {
        case setQuery(String)
        case setPhase(Phase)
        case clear

        case appendResults([Place])
        case setPagination(nextStart: Int, hasMore: Bool)
        case setLoadingMore(Bool)
    }

    struct State {
        var query: String = ""
        var phase: Phase = .idle
        var userLocation: Coordinate?

        // 페이지네이션
        var display: Int = 5
        var nextStart: Int = 1
        var hasMore: Bool = true
        var isLoadingMore: Bool = false
    }

    @Published var state: State

    // 검색 작업이 결과를 반환
    private var searchTask: Task<[Place], Never>?
    private var loadMoreTask: Task<[Place], Never>?

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

            case .scrollReachedBottom:
                Task { @MainActor in
                    loadMore()
                }

            case .tapResult(let place):
                onSelect(place)

            case .dismiss:
                cancelSearch()
                cancelLoadMore()
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
            newState.nextStart = 1
            newState.hasMore = true
            newState.isLoadingMore = false

        case .appendResults(let places):
            let current = newState.phase.results
            let merged = current + places
            newState.phase = .loaded(merged)

        case .setPagination(nextStart: let nextStart, hasMore: let hasMore):
            newState.nextStart = nextStart
            newState.hasMore = hasMore

        case .setLoadingMore(let flag):
            newState.isLoadingMore = flag
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
        cancelLoadMore()

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
            apply(.setPagination(nextStart: 1, hasMore: true))
            apply(.setLoadingMore(false))
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
                    userLocation: userLocation,
                    start: 1
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

            // 첫 페이지 결과 반영 + 페이지네이션 상태 업데이트
            let hasMore = results.count == self.state.display
            let nextStart = 1 + results.count

            let nextPhase: Phase = results.isEmpty ? .empty : .loaded(results)
            apply(.setPhase(nextPhase))
            apply(.setPagination(nextStart: nextStart, hasMore: hasMore))
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

    // MARK: - 페이지네이션

    @MainActor
    func loadMore() {
        // loaded 상태에서만 더 불러오도록 함.
        guard case .loaded = state.phase else { return }
        guard state.hasMore else { return }
        guard !state.isLoadingMore else { return }

        let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        guard let userLocation = state.userLocation else { return }

        let useCase = searchNearbyPlaces
        let start = state.nextStart
        let display = state.display

        cancelLoadMore()
        apply(.setLoadingMore(true))

        loadMoreTask = Task {
            if Task.isCancelled { return [] }

            do {
                let results = try await useCase.execute(
                    query: query,
                    userLocation: userLocation,
                    start: start
                )
                return results
            } catch {
                AppLog.error("Load more failed", category: .network, error: error)
                return []
            }
        }

        Task { @MainActor [weak self] in
            guard let self, let task = self.loadMoreTask else { return }

            defer {
                apply(.setLoadingMore(false))
            }

            let results = await task.value
            if Task.isCancelled { return }

            if !results.isEmpty {
                apply(.appendResults(results))
            }

            let hasMore = results.count == display
            let nextStart = start + results.count

            apply(.setPagination(nextStart: nextStart, hasMore: hasMore))
        }
    }

    func cancelLoadMore() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }
}
