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

    var body: some View {
        VStack {
            if configuration.showsHeader { header }

            if !store.state.messages.isEmpty {
                content
            }

            if configuration.showsFooter && store.state.messages.isEmpty {
                Spacer()

                footer

                Spacer()
            }
        }
        .overlay(alignment: .bottom) {
            if store.state.isEditing {
                selectionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            Task {
                await store.send(intent: .onAppear)
            }
        }
        .onChange(of: store.state.isEditing) { _, _ in
            setTabBarHidden(store.state.isEditing || store.state.deleteStatus != .idle)
        }
        .onChange(of: store.state.deleteStatus) { _, _ in
            setTabBarHidden(store.state.isEditing || store.state.deleteStatus != .idle)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: store.state.isEditing)
        .background(Color.meomunBackgroundColor)
        .customAlert(
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
    }
}

private extension TimelineListView {
    var header: some View {
        ZStack {
            Text(Constants.navigationTitle)
                .font(.headline)
                .foregroundStyle(Color.meomunPrimaryColor)

            if configuration.showsEditButton {
                HStack {
                    Spacer()

                    Button {
                        Task {
                            await store.send(intent: .tapEdit)
                        }
                    } label: {
                        Text(store.state.isEditing ? "취소": "편집")
                            .font(.headline)
                            .foregroundStyle(
                                store.state.messages.isEmpty ? Color.tabInactive : Color.meomunPointColor
                            )
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
                                selectionState: store.selectionState(for: message)
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: store.state.isEditing)
                            .onTapGesture {
                                Task {
                                    await store.send(intent: .tapMessage(message.id))
                                }
                            }
                        }
                    } header: {
                        TimelineSectionHeaderView(yearMonth: section.key)
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

    var footer: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.meomunSecondaryColor)

            Text("END OF RECORDS")
                .font(.footnote.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.meomunSecondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }

    var selectionBar: some View {
        HStack {
            Text(
                store.state.selectedMessageIDs.isEmpty 
                ? "항목을 선택하세요"
                : "\(store.state.selectedMessageIDs.count)개 항목 선택됨"
            )
            .font(.body.weight(.semibold))
            .foregroundStyle(
                store.state.selectedMessageIDs.isEmpty ? Color.tabInactive : Color.meomunPrimaryColor
            )

            Spacer()

            Button {
                Task {
                    await store.send(intent: .requestDeleteSelectedMessages)
                }
            } label: {
                Text("삭제")
                    .font(.headline)
                    .foregroundStyle(store.state.selectedMessageIDs.isEmpty ? Color.tabInactive : Color.red)
                    .padding(.horizontal, 24)
            }
            .disabled(store.state.selectedMessageIDs.isEmpty)
        }
        .floatingContainer()
    }
}

// MARK: - Alert & LoadingOverlay

private extension TimelineListView {
    var deleteAlertBinding: Binding<AlertModel?> {
        Binding(
            get: { store.state.deleteAlert },
            set: { _ in
                Task {
                    await store.send(intent: .dismissAlert)
                }
            }
        )
    }

    var isDeleteLoadingOverlayPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.deleteStatus != .idle },
            set: { _ in }
        )
    }

    var deleteLoadingOverlay: some View {
        LoadingOverlayView(
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
            deleteMessagesUseCase: DeleteMessageUseCaseImpl(messageRepository: MessageRepositoryImpl())
        )
    )
}
