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
    static let placeContainerPlaceholderWhenBlocked = "선택한 장소와 너무 멀어요."
    static let loadingMessage = "머문 흔적을 남기고 있어요."
    static let successMessage = "머문 흔적을 남겼어요."
    static let failMessage = "머문 흔적 남기기에 실패했어요."
}

struct MessageComposerView: View {
    @FocusState var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store: MessageComposerStore

    init(store: MessageComposerStore) {
        _store = StateObject(wrappedValue: store)
    }

    private func send(_ intent: MessageComposerStore.Intent) {
        Task { await store.send(intent: intent) }
    }

    var body: some View {
        ZStack {
            content
                .disabled(store.state.confirmStatus == .sending || store.state.isPlaceSearchPresented)

            if store.state.isPlaceSearchPresented {
                PlaceSearchOverlayView(
                    store: PlaceSearchStore(
                        searchPlaces: SearchNearbyPlaceUseCaseImpl(
                            placeRepository: NaverPlaceSearchRepositoryImpl(
                                network: NetworkClientImpl()
                            )
                        ),
                        userLocation: store.state.startLocation,
                        onSelect: { selected in
                            send(.selectPlace(selected))
                        },
                        onDismiss: {
                            send(.dismissPlaceSearch)
                        }
                    )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(999)
            }

            // TODO: alert 수정할 때 같이 수정해야됨. fail 경우도 추가하기
            if store.state.confirmStatus == .sending || store.state.confirmStatus == .success {
                LoadingOverlayView(
                    mode: store.state.confirmStatus == .success ? .success : .loading,
                    message: store.state.confirmStatus == .sending ? Constants.loadingMessage :
                        Constants.successMessage)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .zIndex(1000)
            }
        }
        .onAppear { send(.onAppear) }
        .onDisappear { send(.onDisappear) }
    }
}

extension MessageComposerView {
    private var content: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()
            editorSection
            Spacer(minLength: 0)
            placeSection
            placeHintSection
            Spacer(minLength: 0)
            confirmSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(backgroundView)
        .onTapGesture { isFocused = false }
        .onChange(of: store.locationProvider.current) { _, current in
            send(.updateCurrentLocation(current))
        }
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
        .customAlert(
            alertBinding,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .toast(toastBinding)
    }

    @ViewBuilder
    private var editorSection: some View {
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

    private var placeSection: some View {
        HStack(spacing: 8) {
            PlaceSearchContainerView {
                Button {
                    isFocused = false
                    send(.tapPlaceField)
                } label: {
                    let isPlaceSelected = store.state.selectedPlace != nil
                    let placeName = store.state.selectedPlace?.name ?? ""

                    Text(store.state.isPlaceTagLocked
                         ? Constants.placeContainerPlaceholderWhenBlocked
                         : isPlaceSelected ? placeName : Constants.placeContainerPlaceholder
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        store.state.isPlaceTagLocked
                        ? Color(.placeholderText)
                        : isPlaceSelected ? Color.tabActive : Color(.placeholderText)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            CancelButton { send(.clearPlace) }
        }
        .disabled(store.state.isPlaceTagLocked)
    }

    private var placeHintSection: some View {
        Text(store.state.placeTagLockedHintMessage)
            .font(.subheadline)
            .foregroundStyle(Color(.placeholderText))
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(store.state.isPlaceTagLocked ? 1.0 : 0.0)
            .accessibilityHidden(store.state.isPlaceTagLocked == false)
    }

    private var confirmSection: some View {
        ConfirmButton(action: { send(.tapConfirm) })
        .disabled(!store.state.isConfirmEnabled)
        .opacity(store.state.isConfirmEnabled ? 1.0 : 0.4)
    }

    private var backgroundView: some View {
        Image(.background)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var messageBinding: Binding<String> {
        Binding(
            get: { store.state.message },
            set: { message in
                send(.setMessage(message))
            }
        )
    }

    private var alertBinding: Binding<AlertModel?> {
        Binding(
            get: { store.state.alert },
            set: { alert in
                send(.setAlert(alert))
            }
        )
    }

    private var toastBinding: Binding<String?> {
        Binding(
            get: { store.state.toastMessage },
            set: { message in
                send(.setToast(message))
            }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

    private var backToolbarButton: some View {
        BackButton {
            if store.state.isPlaceSearchPresented {
                send(.dismissPlaceSearch)
                return
            }

            isFocused = false
            let trimmed = store.state.message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else {
                send(.onDisappear)
                dismiss()
                return
            }

            send(.setAlert(AlertModel(
                title: "작성 중인 말이 있어요",
                message: "지금 나가면 작성 중인 내용이 사라져요. 그대로 나갈까요?",
                buttons: [
                    AlertButtonConfig(
                        title: "그대로 나가기",
                        role: .destructive,
                        action: {
                            send(.resetDraft)
                        }
                    ),
                    AlertButtonConfig(
                        title: "머무르기",
                        role: .cancel,
                        action: nil
                    )
                ]
            )))
        }
        .disabled(store.state.confirmStatus == .sending)
        .opacity(store.state.confirmStatus == .sending ? 0.4 : 1.0)
    }
}

#Preview {
    NavigationStack {
        MessageComposerView(
            store: MessageComposerStore(
                locationProvider: LocationProvider(),
                createMessage: CreateMessageUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                onClose: { _ in
                    print("close")
                }
            )
        )
        .environmentObject(LocationProvider())
    }
}
