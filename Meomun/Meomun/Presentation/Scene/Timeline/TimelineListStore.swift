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
        var deleteAlert: MMAlertModel?
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
        case requestDeleteMessage(MessageID)        // 단일 메시지 삭제 요청 (메뉴 버튼)
        case confirmDeleteMessage(MessageID)        // 단일 메시지 삭제 확인 (메뉴 버튼)
        case dismissAlert                           // 얼럿 - 취소

        case tapMessage(MessageID)
        case tapSection(YearMonth?)
        case tapEdit
        case syncEditing(Bool)
    }

    enum Action {
        case setMessages([Message])
        case addMessages([Message])
        case toggleMessageSelection(MessageID)
        case clearSelectedMessageIDs
        case setSelectedSection(YearMonth?)
        case setEditing(Bool)
        case deleteMessages(Set<MessageID>)
        case showDeleteAlert(MMAlertModel)
        case hideAlert
        case setDeleteStatus(LoadingStatus)
    }

    @Published var state: State

    private let fetchRecentMessagesUseCase: FetchRecentMessagesUseCase
    private let deleteMessagesUseCase: DeleteMessagesUseCase
    private let onDeletedMessages: (Set<MessageID>) -> Void

    init(
        initialMessages: [Message] = [],
        fetchRecentMessagesUseCase: FetchRecentMessagesUseCase,
        deleteMessagesUseCase: DeleteMessagesUseCase,
        onDeletedMessages: @escaping (Set<MessageID>) -> Void = { _ in }
    ) {
        self.state = State(messages: initialMessages)
        self.fetchRecentMessagesUseCase = fetchRecentMessagesUseCase
        self.deleteMessagesUseCase = deleteMessagesUseCase
        self.onDeletedMessages = onDeletedMessages
    }

    func action(intent: Intent) -> AsyncStream<Action> {
        switch intent {
        case .onAppear:
            return .init { continuation in
                guard state.messages.isEmpty else {
                    continuation.finish()
                    return
                }

                Task {
                    do {
                        // TODO: 페이지네이션 구현
                        let messages = try await fetchRecentMessagesUseCase.execute(page: 0, pageSize: 10)
                        continuation.yield(.addMessages(messages))
                    } catch {
                        AppLog.debug(error.localizedDescription, category: .store)
                    }

                    continuation.finish()
                }
            }

        case .tapSection(let section):
            return .init { continuation in
                continuation.yield(.setSelectedSection(section))
                continuation.finish()
            }

        case .tapEdit:
            return .init { continuation in
                continuation.yield(.setEditing(!state.isEditing))
                continuation.yield(.clearSelectedMessageIDs)
                continuation.finish()
            }

        case .syncEditing(let isEditing):
            return .init { continuation in
                continuation.yield(.setEditing(isEditing))
                if isEditing == false {
                    continuation.yield(.clearSelectedMessageIDs)
                }
                continuation.finish()
            }

        case .tapMessage(let messageID):
            return .init { continuation in
                guard state.isEditing else {
                    continuation.finish()
                    return
                }

                continuation.yield(.toggleMessageSelection(messageID))
                continuation.finish()
            }

        case .requestDeleteSelectedMessages:
            return .init { continuation in
                let alert = MMAlertFactory.deleteMessage(
                    count: state.selectedMessageIDs.count,
                    onConfirm: { [weak self] in
                        guard let self else { return }
                        Task {
                            await self.send(intent: .confirmDeleteSelectedMessages)
                        }
                    }
                )
                continuation.yield(.showDeleteAlert(alert))
                continuation.finish()
            }

        case .requestDeleteMessage(let messageID):
            return .init { continuation in
                let alert = MMAlertFactory.deleteMessage(
                    count: 1,
                    onConfirm: { [weak self] in
                        guard let self else { return }
                        Task {
                            await self.send(intent: .confirmDeleteMessage(messageID))
                        }
                    }
                )
                continuation.yield(.showDeleteAlert(alert))
                continuation.finish()
            }

        case .confirmDeleteMessage(let messageID):
            return performDelete(messageIDs: [messageID])

        case .confirmDeleteSelectedMessages:
            return performDelete(
                messageIDs: state.selectedMessageIDs,
                onSuccess: [
                    .setEditing(false),
                    .clearSelectedMessageIDs
                ]
            )

        case .dismissAlert:
            return .init { continuation in
                continuation.yield(.hideAlert)
                continuation.finish()
            }

        case .setMessages(let messages):
            return .init { continuation in
                continuation.yield(.setMessages(messages))
                continuation.finish()
            }
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
            AppLog.debug("[TimelineListStore] Deleted messages: \(newState.messages.count) left", category: .store)

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

// MARK: - Side Effects

private extension TimelineListStore {
    func performDelete(
        messageIDs: Set<MessageID>,
        onSuccess: [Action] = []
    ) -> AsyncStream<Action> {
        AsyncStream { continuation in
            continuation.yield(.setDeleteStatus(.loading))
            continuation.yield(.hideAlert)

            Task {
                do {
                    try await deleteMessagesUseCase.execute(for: messageIDs)
                    continuation.yield(.deleteMessages(messageIDs))
                    self.onDeletedMessages(messageIDs)

                    // 성공 시 추가 액션 실행
                    onSuccess.forEach { continuation.yield($0) }

                    // 성공 메시지를 1초간 보여준 후 idle로 전환
                    continuation.yield(.setDeleteStatus(.success))
                    try? await Task.sleep(for: .seconds(1))
                    continuation.yield(.setDeleteStatus(.idle))
                } catch {
                    AppLog.error("메시지 삭제 실패", category: .store, error: error)
                    // 실패 메시지를 1초간 보여준 후 idle로 전환
                    continuation.yield(.setDeleteStatus(.fail))
                    try? await Task.sleep(for: .seconds(1))
                    continuation.yield(.setDeleteStatus(.idle))
                }

                continuation.finish()
            }
        }
    }
}

// MARK: Section Helper

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

// MARK: - View Helpers

extension TimelineListStore {
    func selectionState(for message: Message) -> TimelineSelectionState {
        if !state.isEditing {
            return .inactive
        }

        return state.selectedMessageIDs.contains(message.id) ? .selected : .unselected
    }

    func messages(in section: YearMonth) -> [Message] {
        state.sections.first(where: { $0.key == section })?.value ?? []
    }
}
