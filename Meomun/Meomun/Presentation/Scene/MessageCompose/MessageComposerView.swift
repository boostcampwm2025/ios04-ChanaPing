//
//  MessageComposeView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "잠시 남겨놓기"
    static let textEditorTitle = "이 말은 잠시 머물 거에요."
    static let textEditorPlaceholder = "지금 느낌 어때요?"
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
    @State private var presentedAlert: AlertModel?

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

            if store.state.isPlaceSearchPresented {
                placeSearchOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(999)
            }

            if store.state.confirmStatus != .idle {
                loadingOverlay
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .zIndex(1000)
            }
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
        .padding(24)
        .background(backgroundView)
        .onTapGesture { isFocused = false }
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
        .customAlert(
            $presentedAlert,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .toast(toastBinding)
    }

    @ViewBuilder
    var editorSection: some View {
        Text(Constants.textEditorTitle)
            .font(.headline.bold())
            .foregroundStyle(Color.meomunSecondaryColor)
            .frame(maxWidth: .infinity, alignment: .leading)

        MessageTextEditor(
            text: messageBinding,
            isFocused: $isFocused,
            maxCount: EditorPolicy.maxCount,
            placeholder: Constants.textEditorPlaceholder
        )
    }

    var placeSection: some View {
        HStack(spacing: 8) {
            PlaceSearchContainerView {
                Button(action: onTapPlaceField) {
                    Text(placeFieldText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(placeFieldColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            CancelButton { send(.clearPlace) }
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
                        network: NetworkClientImpl()
                    )
                ),
                userLocation: store.state.startLocation,
                onSelect: { send(.selectPlace($0)) },
                onDismiss: { send(.dismissPlaceSearch) }
            )
        )
    }

    var loadingOverlay: some View {
        LoadingOverlayView(
            status: store.state.confirmStatus,
            message: loadingOverlayMessage)
    }
}

// MARK: Computed property
private extension MessageComposerView {
    var placeFieldText: String {
        store.state.selectedPlace?.name ?? store.state.startAddress.fromAddressSuffixStart()
    }

    var placeFieldColor: Color {
        store.state.selectedPlace == nil ? Color(.placeholderText) : Color.tabActive
    }

    var loadingOverlayMessage: String {
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
}

// MARK: Toolbar / Actions
private extension MessageComposerView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                backToolbarButton
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                backToolbarButton
            }
        }

        ToolbarItem(placement: .principal) {
            Text(Constants.navigationTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.meomunPrimaryColor)
        }
    }

    var backToolbarButton: some View {
        BackButton(action: onTapBackButton)
        .disabled(store.state.confirmStatus == .loading)
        .opacity(store.state.confirmStatus == .loading ? 0.4 : 1.0)
    }

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

    var exitAlert: AlertModel {
        AlertModel(
            title: Constants.exitAlertTitle,
            message: Constants.exitAlertMessage,
            buttons: [
                AlertButtonConfig(
                    title: Constants.exitAlertPrimaryButtonTitle,
                    role: .destructive,
                    action: { send(.resetDraft) }
                ),
                AlertButtonConfig(
                    title: Constants.exitAlertSecondaryButtonTitle,
                    role: .cancel,
                    action: nil
                )
            ]
        )
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
                        client: NetworkClientImpl()
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
