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
        case selectMessage(MessageID?)
        case requestDeleteMessage(MessageID)
        case confirmDeleteMessage(MessageID)
        case dismissAlert
    }

    enum Action {
        case setLoading(Bool)
        case setMessages([Message])
        case setDomeEnvironment(DomeEnvironment)
        case setError(String)
        case setUserLocation(Coordinate)
        case setCurrentPlaceID(PlaceID)
        case setToastMessage(String?)
        case setSelectedMessage(MessageID?)
        case deleteMessage(MessageID)
        case showDeleteAlert(AlertModel)
        case hideAlert
        case setDeleteStatus(LoadingStatus)
    }

    struct State {
        var isLoading: Bool = false
        var errorMessage: String = ""
        var messages: [Message] = []
        var domeEnvironment: DomeEnvironment?
        var userLocation: Coordinate?           // TODO: - 지도 > 공간 진입 시점 좌표 넘겨주고, 옵셔널 지우기
        var currentPlaceID: PlaceID?
        var toastMessage: String?
        var selectedMessageID: MessageID?
        var deleteAlert: AlertModel?
        var deleteStatus: LoadingStatus = .idle
    }

    @Published var state: State

    private let fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase
    private let deleteMessagesUseCase: DeleteMessagesUseCase

    private var fetchMessagesTask: Task<Void, Never>?

    let place: Place

    init(
        fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase,
        deleteMessagesUseCase: DeleteMessagesUseCase,
        place: Place
    ) {
        self.state = State()
        self.fetchPlaceMessagesUseCase = fetchPlaceMessagesUseCase
        self.deleteMessagesUseCase = deleteMessagesUseCase
        self.place = place
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear(let placeID):
                continuation.yield(.setCurrentPlaceID(placeID))
                continuation.yield(.setDomeEnvironment(.init(dayPart: .current())))
                fetchMessages(for: placeID, continuation: continuation)

            case .setToast(let message):
                continuation.yield(.setToastMessage(message))
                continuation.finish()

            case .selectMessage(let messageID):
                continuation.yield(.setSelectedMessage(messageID))
                continuation.finish()

            case .requestDeleteMessage(let messageID):
                continuation.yield(.setSelectedMessage(nil))
                let alert = AlertFactory.deleteMessage(count: 1) { [weak self] in
                    Task {
                        await self?.send(intent: .confirmDeleteMessage(messageID))
                    }
                }
                continuation.yield(.showDeleteAlert(alert))
                continuation.finish()

            case .confirmDeleteMessage(let messageID):
                performDelete(messageID: messageID, continuation: continuation)

            case .dismissAlert:
                continuation.yield(.hideAlert)
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

        case .setDomeEnvironment(let environment):
            newState.domeEnvironment = environment

        case .setError(let message):
            newState.errorMessage = message

        case .setUserLocation(let location):
            newState.userLocation = location

        case .setCurrentPlaceID(let placeID):
            newState.currentPlaceID = placeID

        case .setToastMessage(let message):
            newState.toastMessage = message

        case .setSelectedMessage(let messageID):
            newState.selectedMessageID = messageID

        case .deleteMessage(let messageID):
            newState.messages.removeAll { $0.id == messageID }

        case .showDeleteAlert(let alert):
            newState.deleteAlert = alert

        case .hideAlert:
            newState.deleteAlert = nil

        case .setDeleteStatus(let status):
            newState.deleteStatus = status
        }

        return newState
    }

}

private extension SpaceStore {
    func fetchMessages(
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

    func performDelete(
        messageID: MessageID,
        continuation: AsyncStream<Action>.Continuation
    ) {
        continuation.yield(.setDeleteStatus(.loading))
        continuation.yield(.hideAlert)

        Task {
            do {
                try await deleteMessagesUseCase.execute(for: [messageID])
                continuation.yield(.deleteMessage(messageID))

                // 성공 피드백 (1초)
                continuation.yield(.setDeleteStatus(.success))
                try? await Task.sleep(for: .seconds(1))
                continuation.yield(.setDeleteStatus(.idle))
            } catch {
                AppLog.error("메시지 삭제 실패", category: .store, error: error)

                // 실패 피드백 (1초)
                continuation.yield(.setDeleteStatus(.fail))
                try? await Task.sleep(for: .seconds(1))
                continuation.yield(.setDeleteStatus(.idle))
            }

            continuation.finish()
        }
    }
}
