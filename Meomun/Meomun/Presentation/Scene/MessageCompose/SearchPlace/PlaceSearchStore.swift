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
        case loaded
        case empty
        case failed(String)
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
        case setResults([Place])
    }

    struct State {
        var query: String = ""
        var phase: Phase = .idle
        var results: [Place] = []
    }

    @Published var state: State = .init()

    private var searchTask: Task<Void, Never>?

    private let searchNearbyPlaces: SearchNearbyPlaceUseCaseProtocol
    private let userLocation: Coordinate

    private let onSelect: (Place) -> Void
    private let onDismiss: () -> Void

    init(
        searchPlaces: SearchNearbyPlaceUseCaseProtocol,
        userLocation: Coordinate,
        onSelect: @escaping (Place) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.searchNearbyPlaces = searchPlaces
        self.userLocation = userLocation
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .queryChanged(let query):
                continuation.yield(.setQuery(query))

                scheduleSearch(for: query)

            case .submit:
                scheduleSearch(for: state.query, immediate: true)

            case .tapResult(let place):
                onSelect(place)

            case .dismiss:
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

        case .setResults(let results):
            newState.results = results
        }

        return newState
    }

    private func performSearch(query: String) async {
        await MainActor.run {
            self.state.phase = .loading
            self.state.results = []
        }

        do {
            // TODO: 사용자 위치 기준 반경 60m 이내 검색 결과만 표시하도록 필터링 로직 추가
            let results = try await searchNearbyPlaces.execute(
                query: query,
                userLocation: userLocation,
                radiusMeters: 60
            )

            if Task.isCancelled { return }

            await MainActor.run {
                self.state.results = results
                self.state.phase = results.isEmpty ? .empty : .loaded
            }
        } catch {
            if Task.isCancelled { return }

            if case let NetworkError.serverError(statusCode, data) = error {
                print("LocalSearch status:", statusCode)
                if let data { print(String(data: data, encoding: .utf8) ?? "") }
            } else {
                print("LocalSearch error:", error)
            }

            await MainActor.run {
                self.state.phase = .failed("검색 중 오류가 발생했습니다.")
            }
        }
    }

    private func scheduleSearch(for rawQuery: String, immediate: Bool = false) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        searchTask?.cancel()

        guard !query.isEmpty else {
            Task { @MainActor in
                self.state.phase = .idle
                self.state.results = []
            }
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }

            if !immediate {
                // 디바운스 300ms
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            if Task.isCancelled { return }

            await self.performSearch(query: query)
        }
    }
}
