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

        var sections: [(key: YearMonth, value: [Message])] {
            MessageTimelineGrouper.groupByYearMonth(messages)
        }
    }

    enum Intent: Equatable {
        case onAppear
        case setMessages([Message])
        case deleteMessages([Message.ID])

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
        case deleteMessages([Message.ID])
    }

    @Published var state: State

    private let fetchRecentMessagesUseCase: FetchRecentMessagesUseCase

    init(initialMessages: [Message] = [], fetchRecentMessagesUseCase: FetchRecentMessagesUseCase) {
        self.state = State(messages: initialMessages)
        self.fetchRecentMessagesUseCase = fetchRecentMessagesUseCase
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

            case .deleteMessages(let ids):
                // TODO: 메시지 삭제 동작 구현
                continuation.yield(.deleteMessages(ids))

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

        case .deleteMessages(let ids):
            let idSet = Set(ids)
            newState.messages.removeAll { idSet.contains($0.id) }
            cleanupSectionIfNeeded(&newState)
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
