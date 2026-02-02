//
//  MessageComposeView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "머물기"
    static let textEditorTitle = "지금 이 공간에 남겨볼까요?"
    static let textEditorPlaceholder = "여기서 떠오른 한 줄을 적어보세요."
    static let placeTip = """
    장소 태그는 선택이에요.
    지금 위치 그대로 기록하거나, 원하는 장소를 직접 선택할 수 있어요.
    """
    static let placeContainerPlaceholder = "지금 어디에 있나요?"

    static let loadingMessage = "머문 흔적을 남기고 있어요."
    static let successMessage = "머문 흔적을 남겼어요."
    static let failMessage = "머문 흔적 남기기에 실패했어요."

    static let exitAlertTitle = "지금 작성 중인 말이 있어요."
    static let exitAlertMessage = "지금 나가면 작성 중인 내용이 사라져요. 그대로 나갈까요?"
    static let exitAlertPrimaryButtonTitle = "그대로 나가기"
    static let exitAlertSecondaryButtonTitle = "머무르기"
}

struct MessageComposerView: View {
    @FocusState var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store: MessageComposerStore
    @State private var presentedAlert: MMAlertModel?

    init(store: MessageComposerStore) {
        _store = StateObject(wrappedValue: store)
        _presentedAlert = State(initialValue: store.state.alert)
    }

    private func send(_ intent: MessageComposerStore.Intent) {
        Task { await store.send(intent: intent) }
    }

    var body: some View {
        ZStack {
            content
                .disabled(isInteractionDisabled)
        }
        .enableSwipeBack(
            shouldBegin: {
                // 로딩 중이면 swipe back 금지
                if store.state.confirmStatus == .loading { return false }

                // 장소 검색 overlay가 떠있으면 pop 금지
                if store.state.isPlaceSearchPresented { return false }

                // draft 존재하면 pop 금지 (경고 띄우는 형태로 유도)
                if !isDraftEmpty { return false }

                return true
            },
            onAttempt: {
                // swipe 시도했는데 막혔을 때
                if store.state.isPlaceSearchPresented {
                    send(.dismissPlaceSearch)
                    return
                }

                if store.state.confirmStatus == .loading {
                    send(.setToast(Constants.loadingMessage))
                    return
                }

                if !isDraftEmpty {
                    send(.setAlert(exitAlert))
                }
            }
        )
        .overlay(alignment: .top) {
            ComposeTopBar(
                title: Constants.navigationTitle,
                onBack: { onTapBackButton() }
            )
            .padding(.top, 12)
            .disabled(store.state.confirmStatus == .loading)
            .opacity(store.state.confirmStatus == .loading ? 0.4 : 1.0)
        }
        .onAppear { send(.onAppear) }
        .onChange(of: store.state.alert) { _, newValue in
            guard presentedAlert != newValue else { return }
            presentedAlert = newValue
        }
        .onChange(of: presentedAlert) { _, newValue in
            guard store.state.alert != newValue else { return }
            send(.setAlert(newValue))
        }
        .onChange(of: store.state.showEmptyLocationAlert) { _, show in
            if show {
                presentedAlert = emptyLocationAlert
            }
        }
        .fullScreenCover(isPresented: isPlaceSearchPresentedBinding) {
            placeSearchOverlay
                .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: isMMLoadingOverlayPresentedBinding) {
            mmLoadingOverlay
                .presentationBackground(.clear)
                .interactiveDismissDisabled(true)
        }
        .transaction { $0.disablesAnimations = true }
    }
}

// MARK: Subviews
private extension MessageComposerView {
    var content: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()
            editorSection
            Spacer(minLength: 0)
            placeSection
            Spacer(minLength: 0)
            confirmSection
            Spacer(minLength: 0)
        }
        .padding(.top, 54)
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .background(backgroundView)
        .onTapGesture { isFocused = false }
        .navigationBarBackButtonHidden()
        .mmAlert(
            $presentedAlert,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .mmToast(toastBinding)
    }

    @ViewBuilder
    var editorSection: some View {
        Text(Constants.textEditorTitle)
            .font(.headline.bold())
            .foregroundStyle(Color.mmSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)

        MessageTextEditor(
            text: messageBinding,
            isFocused: $isFocused,
            maxCount: MessageComposerPolicy.maxCount,
            placeholder: Constants.textEditorPlaceholder
        )
    }

    var placeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Constants.placeTip)
                .font(.caption)
                .foregroundStyle(Color.mmSecondary)
                .lineSpacing(3)

            HStack(spacing: 8) {
                Button(action: onTapPlaceField) {
                    PlaceSearchContainerView {
                        Text(placeFieldText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(placeFieldColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                CancelButton { send(.clearPlace) }
            }
        }
    }

    var confirmSection: some View {
        ConfirmButton(action: { send(.tapConfirm) })
        .disabled(!store.state.isConfirmEnabled)
        .opacity(store.state.isConfirmEnabled ? 1.0 : 0.4)
    }

    var backgroundView: some View {
        Image(.background)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    var placeSearchOverlay: some View {
        PlaceSearchOverlayView(
            store: PlaceSearchStore(
                searchPlaces: SearchNearbyPlaceUseCaseImpl(
                    placeRepository: NaverPlaceSearchRepositoryImpl(
                        remote: SupabaseServiceImpl(network: NetworkClientImpl())
                    )
                ),
                userLocation: store.state.startLocation,
                onSelect: { send(.selectPlace($0)) },
                onDismiss: { send(.dismissPlaceSearch) }
            )
        )
    }

    var mmLoadingOverlay: some View {
        MMLoadingOverlayView(
            status: store.state.confirmStatus,
            message: mmLoadingOverlayMessage
        )
    }
}

// MARK: Computed property
private extension MessageComposerView {
    var placeFieldText: String {
        store.state.selectedPlace?.name ?? store.state.startAddress.fromAddressSuffixStart()
    }

    var placeFieldColor: Color {
        store.state.selectedPlace == nil ? Color.mmTabInactive : Color.mmTabActive
    }

    var mmLoadingOverlayMessage: String {
        switch store.state.confirmStatus {
        case .loading: return Constants.loadingMessage
        case .success: return Constants.successMessage
        case .fail: return Constants.failMessage
        case .idle: return ""
        }
    }

    var isInteractionDisabled: Bool {
        store.state.confirmStatus == .loading || store.state.isPlaceSearchPresented
    }

    var isDraftEmpty: Bool {
        store.state.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: Bindings
private extension MessageComposerView {
    var messageBinding: Binding<String> {
        Binding(
            get: { store.state.message },
            set: { send(.setMessage($0)) }
        )
    }

    var toastBinding: Binding<String?> {
        Binding(
            get: { store.state.toastMessage },
            set: { send(.setToast($0)) }
        )
    }

    var isPlaceSearchPresentedBinding: Binding<Bool> {
        Binding(
            get: {
                store.state.isPlaceSearchPresented && store.state.confirmStatus == .idle
            },
            set: { isPresented in if !isPresented { send(.dismissPlaceSearch) } }
        )
    }

    var isMMLoadingOverlayPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.state.confirmStatus != .idle },
            set: { _ in }
        )
    }
}

// MARK: Actions
private extension MessageComposerView {
    func onTapPlaceField() {
        isFocused = false
        send(.tapPlaceField)
    }

    func onTapBackButton() {
        if store.state.isPlaceSearchPresented {
            send(.dismissPlaceSearch)
            return
        }

        isFocused = false

        guard !isDraftEmpty else {
            dismiss()
            return
        }

        send(.setAlert(exitAlert))
    }

    var exitAlert: MMAlertModel {
        MMAlertModel(
            title: Constants.exitAlertTitle,
            message: Constants.exitAlertMessage,
            buttons: [
                MMAlertButtonConfig(
                    title: Constants.exitAlertPrimaryButtonTitle,
                    role: .destructive,
                    action: { send(.resetDraft) }
                ),
                MMAlertButtonConfig(
                    title: Constants.exitAlertSecondaryButtonTitle,
                    role: .cancel,
                    action: nil
                )
            ]
        )
    }

    var emptyLocationAlert: MMAlertModel {
        MMAlertModel(title: "위치 정보를 가져올 수 없어요.", message: "네트워크 연결을 확인해주세요.", buttons: [
            .init(title: "그대로 작성", role: .normal, action: {
                send(.confirmWithEmptyLocation)
            }),
            .init(title: "새로 고침", role: .cancel, action: {
                send(.retryReverseGeocoding)
            })
        ])
    }
}

#Preview {
    NavigationStack {
        MessageComposerView(
            store: MessageComposerStore(
                currentLocation: Coordinate.seoulCity,
                currentPlace: Place(
                    id: PlaceID(value: "placeId"),
                    name: "Place Name",
                    coordinate: .init(
                        latitude: 0,
                        longitude: 0
                    )
                ),
                createMessage: CreateMessageUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                reverseGeocoding: ReverseGeocodeUseCaseImpl(
                    repository: ReverseGeocodeRepositoryImpl(
                        remote: SupabaseServiceImpl(network: NetworkClientImpl())
                    )
                ),
                onClose: { _ in
                    print("close")
                }
            )
        )
        .environmentObject(LocationProvider())
    }
}
