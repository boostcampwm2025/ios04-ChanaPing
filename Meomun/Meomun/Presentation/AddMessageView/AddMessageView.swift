//
//  AddMessageView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct AddMessageView: View {
    @StateObject private var viewModel = TextModerationViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("텍스트 안전성 검사(임시 데모)")
                .font(.headline)

            TextEditor(text: $viewModel.inputText)
                .frame(height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.4))
                )

            HStack(spacing: 10) {
                Button("검사하기") {
                    Task { await viewModel.runModeration() }
                }
                .buttonStyle(.borderedProminent)

                if case .loading = viewModel.state {
                    ProgressView()
                }
            }

            resultView
                .padding(.top, 4)

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var resultView: some View {
        switch viewModel.state {
        case .idle:
            Text("텍스트를 입력하고 검사하기를 눌러줘.")
                .foregroundStyle(.secondary)

        case .loading:
            Text("검사 중…")
                .foregroundStyle(.secondary)

        case .success(let r):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("판정:").foregroundStyle(.secondary)
                    Text(r.decision.rawValue).font(.title3).bold()
                }
                Text("라벨: \(r.labels.joined(separator: ", "))")
                    .foregroundStyle(.secondary)
                Text(String(format: "확신도: %.2f", r.score))
                    .foregroundStyle(.secondary)
                Text("사유: \(r.reason)")
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

        case .failure(let msg):
            Text("오류: \(msg)")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    AddMessageView()
}
