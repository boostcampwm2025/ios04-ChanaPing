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

        var sections: [(key: YearMonth, value: [Message])] {
            MessageTimelineGrouper.groupByYearMonth(messages)
        }
    }

    enum Intent: Equatable {
        case onAppear
        case setMessages([Message])
        case deleteMessages([Message.ID])

        case tapSection(YearMonth)
        case tapEdit
    }

    enum Action {
        case setMessages([Message])
        case addMessages([Message])
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
                // TODO: 편집 버튼 탭 동작 구현
                continuation.yield(.setEditing(!state.isEditing))

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
