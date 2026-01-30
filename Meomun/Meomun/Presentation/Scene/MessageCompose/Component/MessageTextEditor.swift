//
//  MessageTextEditor.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct MessageTextEditor: View {
    @Binding private var text: String
    @FocusState.Binding private var isFocused: Bool
    @State private var localText: String = ""

    let maxCount: Int
    let placeholder: String

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        maxCount: Int,
        placeholder: String
    ) {
        self._text = text
        self._isFocused = isFocused
        self._localText = State(initialValue: text.wrappedValue)
        self.maxCount = maxCount
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.mmContainerBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.mmPrimary.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2)
                .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)

            VStack {
                // Editor + placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $localText)
                        .focused($isFocused)
                        .font(.body.bold())
                        .foregroundStyle(Color.mmTextBrand.opacity(0.8))
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 22)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .submitLabel(.done)
                        .onChange(of: localText) { _, newValue in
                            let filtered = newValue
                                .replacingOccurrences(of: "\n", with: "")
                                .replacingOccurrences(of: "\r", with: "")

                            if filtered.count > maxCount {
                                localText = String(filtered.prefix(maxCount))
                            } else {
                                localText = filtered
                            }

                            text = localText

                            if newValue.contains("\n") || newValue.contains("\r") {
                                $isFocused.wrappedValue = false
                            }
                        }
                        .onChange(of: text) { _, newValue in
                            if newValue != localText {
                                localText = newValue
                            }
                        }

                    if text.isEmpty {
                        Text(placeholder)
                            .font(.body.bold())
                            .foregroundStyle(Color.mmTextBrand.opacity(0.3))
                            .padding(.horizontal, 24)
                            .padding(.top, 26)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    // Counter pill
                    Text("\(text.count) / \(maxCount)")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.mmSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mmPrimary.opacity(0.05), in: Capsule())

                    Spacer()

                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.mmSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .frame(height: 140)
        .onTapGesture {
            $isFocused.wrappedValue = true
        }
    }
}

#Preview {
    @Previewable @State var message: String = ""
    @Previewable @FocusState var isFocused: Bool

    MessageTextEditor(text: $message, isFocused: $isFocused, maxCount: 30, placeholder: "지금 느낌 어때요?")
}
