//
//  TimelineListView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "머물렀던 순간들"

    static let deleteLoadingMessage = "메시지를 삭제하고 있어요."
    static let deleteSuccessMessage = "메시지를 삭제했어요."
    static let deleteFailMessage = "메시지 삭제 실패\n다시 시도해주세요."
}

struct TimelineListView: View {
    @Environment(\.setTabBarHidden) private var setTabBarHidden
    @StateObject private var store: TimelineListStore
    private let configuration: Configuration

    init(store: TimelineListStore, configuration: Configuration = .full) {
        _store = StateObject(wrappedValue: store)
        self.configuration = configuration
    }

    private func send(_ intent: TimelineListStore.Intent) {
        Task { await store.send(intent: intent) }
    }

    var body: some View {
        VStack {
            if configuration.showsHeader { header }

            if !store.state.messages.isEmpty {
                content
            } else {
                emptyContent
            }
        }
        .overlay(alignment: .bottom) {
            if store.state.isEditing {
                selectionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { send(.onAppear) }
        .onChange(of: store.state.isEditing) { _, _ in
            setTabBarHidden(shouldHideTabBar)
        }
        .onChange(of: store.state.deleteStatus) { _, _ in
            setTabBarHidden(shouldHideTabBar)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: store.state.isEditing)
        .background(Color.mmBackground)
        .mmAlert(
            deleteAlertBinding,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .overlay {
            if store.state.deleteStatus != .idle {
                deleteLoadingOverlay
                    .transition(.identity) // 애니메이션 없음
            }
        }
        .overlay {
            if store.state.selectedSection != nil {
                sectionOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.state.selectedSection != nil)
    }
}

// MARK: Subviews
private extension TimelineListView {
    var header: some View {
        ZStack {
            Text(Constants.navigationTitle)
                .font(.headline)
                .foregroundStyle(Color.mmTextBrand)

            if configuration.showsEditButton {
                HStack {
                    Spacer()

                    Button { send(.tapEdit) } label: {
                        Text(store.state.isEditing ? "취소": "편집")
                            .font(.headline)
                            .foregroundStyle(editButtonColor)
                    }
                    .disabled(store.state.messages.isEmpty)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(store.state.sections, id: \.key) { section in
                    Section {
                        let monthMessages = section.value

                        ForEach(Array(monthMessages.enumerated()), id: \.element.id) { index, message in
                            TimelineRowView(
                                message: message,
                                showTopLine: index != 0,
                                showBottomLine: index != monthMessages.count - 1,
                                selectionState: store.selectionState(for: message),
                                onDelete: {
                                    Task {
                                        await store.send(intent: .requestDeleteMessage(message.id))
                                    }
                                }
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: store.state.isEditing)
                            .onTapGesture { send(.tapMessage(message.id)) }
                        }
                    } header: {
                        TimelineSectionHeaderView(
                            yearMonth: section.key,
                            onTapButton: {
                                Task {
                                    guard !store.state.isEditing else { return }
                                    await store.send(intent: .tapSection(section.key))
                                }
                            }
                        )
                    }
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 16)

            if configuration.showsFooter && !store.state.messages.isEmpty {
                footer
            }
        }
    }

    var emptyContent: some View {
        Group {
            if configuration.showsFooter {
                Spacer()
                footer
                Spacer()
            }
        }
    }

    var footer: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.mmSecondary)

            Text("END OF RECORDS")
                .font(.footnote.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.mmSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }

    var selectionBar: some View {
        HStack {
            Text(selectionBarText)
            .font(.body.weight(.semibold))
            .foregroundStyle(selectionBarTextColor)

            Spacer()

            Button { send(.requestDeleteSelectedMessages) } label: {
                Text("삭제")
                    .font(.headline)
                    .foregroundStyle(deleteButtonColor)
                    .padding(.horizontal, 24)
            }
            .disabled(store.state.selectedMessageIDs.isEmpty)
        }
        .mmFloatingContainer()
    }
}

// MARK: - Computed Properties
private extension TimelineListView {
    var shouldHideTabBar: Bool {
        store.state.isEditing || store.state.deleteStatus != .idle
    }

    var editButtonColor: Color {
        store.state.messages.isEmpty ? Color.tabInactive : Color.tabActive
    }

    var selectionBarText: String {
        store.state.selectedMessageIDs.isEmpty
        ? "항목을 선택하세요"
        : "\(store.state.selectedMessageIDs.count)개 항목 선택됨"
    }

    var selectionBarTextColor: Color {
        store.state.selectedMessageIDs.isEmpty ? Color.tabInactive : Color.mmTextBrand
    }

    var deleteButtonColor: Color {
        store.state.selectedMessageIDs.isEmpty ? Color.tabInactive : Color.red
    }
}

// MARK: PathRecordOverlay
private extension TimelineListView {
    var isSelectedSectionOverlayPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.selectedSection != nil },
            set: { isPresented in
                guard isPresented == false else { return }
                send(.tapSection(nil))
            }
        )
    }

    @ViewBuilder
    var sectionOverlay: some View {
        if let section = store.state.selectedSection {
            PathRecordOverlayView(
                section: section,
                messages: store.messages(in: section),
                onDismiss: { send(.tapSection(nil)) }
            )
        }
    }
}

// MARK: - Alert & LoadingOverlay
private extension TimelineListView {
    var deleteAlertBinding: Binding<MMAlertModel?> {
        Binding(
            get: { store.state.deleteAlert },
            set: { _ in send(.dismissAlert) }
        )
    }

    var isDeleteLoadingOverlayPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.deleteStatus != .idle },
            set: { _ in }
        )
    }

    var deleteLoadingOverlay: some View {
        MMLoadingOverlayView(
            status: store.state.deleteStatus,
            message: deleteLoadingOverlayMessage
        )
    }

    var deleteLoadingOverlayMessage: String {
        switch store.state.deleteStatus {
        case .loading: return Constants.deleteLoadingMessage
        case .success: return Constants.deleteSuccessMessage
        case .fail: return Constants.deleteFailMessage
        case .idle: return ""
        }
    }
}

extension TimelineListView {
    struct Configuration: Equatable {
        var showsHeader: Bool
        var showsFooter: Bool
        var showsEditButton: Bool

        static let full = Configuration(showsHeader: true, showsFooter: true, showsEditButton: true)

        static let bottomSheet = Configuration(showsHeader: false, showsFooter: false, showsEditButton: false)
    }
}

#Preview {
    let messages: [Message] =  [
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-7 * 60),
            content: "[Case4] NoPlace 스택 메시지 1",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-30 * 60),
            content: "[Case4] NoPlace 스택 메시지 2",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-15000 * 60),
            content: "[Case4] NoPlace 스택 메시지 3",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        )
    ]

    TimelineListView(
        store: TimelineListStore(
            initialMessages: messages,
            fetchRecentMessagesUseCase: FetchRecentMessagesUseCaseImpl(
                repository: MessageRepositoryImpl(storage: MessageInMemoryStorage.shared)
            ),
            deleteMessagesUseCase: DeleteMessagesUseCaseImpl(messageRepository: MessageRepositoryImpl())
        )
    )
}
