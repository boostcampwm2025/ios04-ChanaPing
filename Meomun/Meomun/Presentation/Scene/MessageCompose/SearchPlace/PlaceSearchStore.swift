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

    private let searchPlaces: SearchPlaceUseCaseProtocol
    private let onSelect: (Place) -> Void
    private let onDismiss: () -> Void

    init(
        searchPlaces: SearchPlaceUseCaseProtocol,
        onSelect: @escaping (Place) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.searchPlaces = searchPlaces
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
            // TODO: near 현재 위치로 교체
            let results = try await searchPlaces.execute(
                query: query,
                near: Coordinate(latitude: 0.0, longitude: 0.0)
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

        // 이전 검색 취소
        searchTask?.cancel()

        // 빈 값이면 초기화
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
