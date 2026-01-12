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

    @StateObject private var store = MessageComposerStore()

    var body: some View {
        ZStack {
            content

            if store.state.isPlaceSearchPresented {
                PlaceSearchOverlayView(
                    onSelect: { selected in
                        Task { await store.send(intent: .selectPlace(selected)) }
                    },
                    onDismiss: {
                        Task { await store.send(intent: .dismissPlaceSearch) }
                    }
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

            MessageTextEditor(text: Binding(
                get: {
                    store.state.message
                }, set: { newValue in
                    Task {
                        await store.send(intent: .setMessage(newValue))
                    }
                }
            ))
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

            PlaceTagSlider(places: store.state.suggestPlaces) { selected in
                Task { await store.send(intent: .selectSuggestedPlace(selected))}
            }

            Spacer(minLength: 0)

            ConfirmButton(action: {
                Task { await store.send(intent: .tapConfirm)}
            })

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
    }
}

#Preview {
    @Previewable @State var message: String = ""

    NavigationStack {
        MessageComposerView()
    }
}
