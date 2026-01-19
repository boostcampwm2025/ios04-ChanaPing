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
    static let textEditorPlaceholder = "지금 어디에 있나요?"
}

struct MessageComposerView: View {
    @FocusState var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store: MessageComposerStore

    init(store: MessageComposerStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ZStack {
            content

            if store.state.isPlaceSearchPresented {
                PlaceSearchOverlayView(
                    store: PlaceSearchStore(
                        searchPlaces: SearchNearbyPlaceUseCaseImpl(
                            placeRepository: NaverPlaceSearchRepositoryImpl(
                                network: NetworkClientImpl()
                            )
                        ),
                        userLocation: store.state.userLocation,
                        onSelect: { selected in
                            Task { await store.send(intent: .selectPlace(selected.name)) }
                        },
                        onDismiss: {
                            Task { await store.send(intent: .dismissPlaceSearch) }
                        }
                    )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(999)
            }
        }
    }
}

extension MessageComposerView {
    private var content: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            Text(Constants.textEditorTitle)
                .font(.headline.bold())
                .foregroundStyle(Color.meomunSecondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            MessageTextEditor(text: messageBinding)
            .focused($isFocused)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                PlaceSearchContainerView {
                    Button {
                        isFocused = false
                        Task { await store.send(intent: .tapPlaceField) }
                    } label: {
                        Text(store.state.placeText.isEmpty ? Constants.textEditorPlaceholder : store.state.placeText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(store.state.placeText.isEmpty ? Color(.placeholderText) : Color.tabActive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                CancelButton {
                    Task { await store.send(intent: .clearPlace) }
                }
            }

            Spacer(minLength: 0)

            ConfirmButton(action: {
                Task { await store.send(intent: .tapConfirm)}
            })
            .disabled(!store.state.isConfirmEnabled)
            .opacity(store.state.isConfirmEnabled ? 1.0 : 0.4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background {
            Image(.background)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .onTapGesture {
            isFocused = false
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton {
                        dismiss()
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text(Constants.navigationTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.meomunPrimaryColor)
            }
        }
        .alert(item: alertBinding) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"), action: {
                    Task { await store.send(intent: .dismissAlert) }
                })
            )
        }
        .overlay(alignment: .bottom) {
            if let toast = store.state.toastMessage {
                ToastView(message: toast)
                    .padding(.bottom, 32)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            Task {
                                await store.send(intent: .dismissToast)
                            }
                        }
                    }
            }
        }
    }

    private var messageBinding: Binding<String> {
        Binding(
            get: { store.state.message },
            set: { newValue in
                Task { await store.send(intent: .setMessage(newValue)) }
            }
        )
    }

    private var alertBinding: Binding<MessageComposerStore.AlertState?> {
        Binding(
            get: { store.state.alert },
            set: { _ in Task { await store.send(intent: .dismissAlert) } }
        )
    }
}

#Preview {
    @Previewable @State var message: String = ""

    NavigationStack {
        MessageComposerView(
            store: MessageComposerStore(
                userLocation: .init(
                    latitude: 37.5665,
                    longitude: 126.9780
                ),
                createMessage: CreateMessageUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                onClose: {
                    print("close")
                }
            )
        )
    }
}
