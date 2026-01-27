//
//  TimelineListStore.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import Foundation
import Combine

final class TimelineListStore: Store {
    struct State: Equatable {
        var messages: [Message] = []
        var selectedSection: YearMonth?
        var isEditing: Bool = false

        var selectedMessageIDs: Set<MessageID> = []     // 편집 모드 시 선택 된 메시지
        var deleteAlert: AlertModel?
        var deleteStatus: LoadingStatus = .idle

        var sections: [(key: YearMonth, value: [Message])] {
            MessageTimelineGrouper.groupByYearMonth(messages)
        }
    }

    enum Intent: Equatable {
        case onAppear
        case setMessages([Message])
        case requestDeleteSelectedMessages          // 편집 모드 -> 삭제
        case confirmDeleteSelectedMessages          // 얼럿 - 삭제
        case dismissAlert                           // 얼럿 - 취소

        case tapMessage(MessageID)
        case tapSection(YearMonth)
        case tapEdit
    }

    enum Action {
        case setMessages([Message])
        case addMessages([Message])
        case toggleMessageSelection(MessageID)
        case clearSelectedMessageIDs
        case setSelectedSection(YearMonth?)
        case setEditing(Bool)
        case deleteMessages(Set<MessageID>)
        case showDeleteAlert(AlertModel)
        case hideAlert
        case setDeleteStatus(LoadingStatus)
    }

    @Published var state: State

    private let fetchRecentMessagesUseCase: FetchRecentMessagesUseCase
    private let deleteMessagesUseCase: DeleteMessagesUseCase

    init(
        initialMessages: [Message] = [],
        fetchRecentMessagesUseCase: FetchRecentMessagesUseCase,
        deleteMessagesUseCase: DeleteMessagesUseCase
    ) {
        self.state = State(messages: initialMessages)
        self.fetchRecentMessagesUseCase = fetchRecentMessagesUseCase
        self.deleteMessagesUseCase = deleteMessagesUseCase
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        AsyncStream { continuation in
            switch intent {
            case .onAppear:
                Task {
                    do {
                        // TODO: 페이지네이션 구현
                        let messages = try await fetchRecentMessagesUseCase.execute(page: 0, pageSize: 10)
                        continuation.yield(.addMessages(messages))
                    } catch {
                        AppLog.debug(error.localizedDescription, category: .store)
                    }
                }
                return

            case .tapSection(let section):
                // TODO: 섹션 탭 동작 구현
                continuation.yield(.setSelectedSection(section))

            case .tapEdit:
                continuation.yield(.setEditing(!state.isEditing))
                continuation.yield(.clearSelectedMessageIDs)

            case .tapMessage(let messageID):
                guard state.isEditing else { break }
                continuation.yield(.toggleMessageSelection(messageID))

            case .requestDeleteSelectedMessages:
                let alert = AlertFactory.deleteMessage(
                    count: state.selectedMessageIDs.count,
                    onConfirm: { [weak self] in
                        guard let self else { return }
                        Task {
                            await self.send(intent: .confirmDeleteSelectedMessages)
                        }
                    }
                )
                continuation.yield(.showDeleteAlert(alert))

            case .confirmDeleteSelectedMessages:
                continuation.yield(.setDeleteStatus(.loading))
                continuation.yield(.hideAlert)

                Task {
                    do {
                        try await deleteMessagesUseCase.execute(for: state.selectedMessageIDs)
                        continuation.yield(.deleteMessages(state.selectedMessageIDs))
                        continuation.yield(.setEditing(false))
                        continuation.yield(.clearSelectedMessageIDs)
                        continuation.yield(.setDeleteStatus(.success))

                        // 성공 메시지를 1초간 보여준 후 idle로 전환
                        try? await Task.sleep(for: .seconds(1))
                        continuation.yield(.setDeleteStatus(.idle))
                    } catch {
                        AppLog.error("메시지 삭제 실패", category: .store, error: error)
                        continuation.yield(.setDeleteStatus(.fail))

                        // 실패 메시지를 1초간 보여준 후 idle로 전환
                        try? await Task.sleep(for: .seconds(1))
                        continuation.yield(.setDeleteStatus(.idle))
                    }

                    continuation.finish()
                }
                return

            case .dismissAlert:
                continuation.yield(.hideAlert)

            case .setMessages(let messages):
                continuation.yield(.setMessages(messages))
            }

            continuation.finish()
        }
    }

    func reduce(state: State, action: Action) -> State {
        var newState = state

        switch action {
        case .setMessages(let messages):
            newState.messages = messages
            cleanupSectionIfNeeded(&newState)

        case .addMessages(let messages):
            newState.messages += messages

        case .toggleMessageSelection(let messageID):
            if newState.selectedMessageIDs.contains(messageID) {
                // 이미 선택되어 있으면 -> 선택 해제
                newState.selectedMessageIDs.remove(messageID)
            } else {
                // 선택되어 있지 않으면 -> 선택
                newState.selectedMessageIDs.insert(messageID)
            }

        case .clearSelectedMessageIDs:
            newState.selectedMessageIDs.removeAll()

        case .setSelectedSection(let section):
            newState.selectedSection = section

        case .setEditing(let isEditing):
            newState.isEditing = isEditing

        case .deleteMessages(let messageIDs):
            newState.messages.removeAll { messageIDs.contains($0.id) }
            newState.selectedMessageIDs.subtract(messageIDs)
            cleanupSectionIfNeeded(&newState)

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

private extension TimelineListStore {
    func isSectionAvailable(_ section: YearMonth, in messages: [Message]) -> Bool {
        MessageTimelineGrouper
            .groupByYearMonth(messages)
            .contains(where: { $0.key == section })
    }

    func cleanupSectionIfNeeded(_ state: inout State) {
        guard let selected = state.selectedSection else { return }

        let hasSection = MessageTimelineGrouper
            .groupByYearMonth(state.messages)
            .contains { $0.key == selected }

        if hasSection == false {
            state.selectedSection = nil
        }
    }
}

extension TimelineListStore {
    func selectionState(for message: Message) -> TimelineSelectionState {
        if !state.isEditing {
            return .inactive
        }

        return state.selectedMessageIDs.contains(message.id) ? .selected : .unselected
    }
}
