//
//  MessageTextEditor.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct MessageTextEditor: View {
    @Binding private var text: String

    let maxCount: Int
    let placeholder: String

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        maxCount: Int = 30,
        placeholder: String = "지금 느낌 어때요?"
    ) {
        self._text = text
        self.maxCount = maxCount
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.meomunPrimaryColor.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2)
                .shadow(color: .black.opacity(0.05), radius: 0, x: 1, y: 1)

            VStack {
                // Editor + placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .font(.body.bold())
                        .foregroundStyle(Color.meomunPrimaryColor.opacity(0.8))
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 22)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxCount {
                                text = String(newValue.prefix(maxCount))
                            }
                        }

                    if text.isEmpty {
                        Text(placeholder)
                            .font(.body.bold())
                            .foregroundStyle(Color.meomunPrimaryColor.opacity(0.3))
                            .padding(.horizontal, 24)
                            .padding(.top, 26)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    // Counter pill
                    Text("\(text.count) / \(maxCount)")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.meomunSecondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.meomunPrimaryColor.opacity(0.05), in: Capsule())

                    Spacer()

                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.meomunSecondaryColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .frame(height: 140)
        .onTapGesture {
            isFocused = true
        }
    }
}

#Preview {
    @Previewable @State var message: String = ""

    MessageTextEditor(text: $message)
}
