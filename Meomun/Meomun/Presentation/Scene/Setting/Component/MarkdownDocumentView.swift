//
//  MarkdownDocumentView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI

struct MarkdownDocumentView: View {
    @State private var markdownText: String = ""
    @State private var loadErrorMessage: String?

    private let title: String
    private let resourceName: String

    init(title: String, resourceName: String) {
        self.title = title
        self.resourceName = resourceName
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let loadErrorMessage {
                    Text(title)
                        .font(.title2)
                        .bold()

                    Text(loadErrorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("파일(\(resourceName).md)을 앱 번들에 추가했는지,\n그리고 Target Membership이 현재 앱 타겟으로 체크되어 있는지 확인해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else if markdownText.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    MarkdownView(markdownText)
                }
            }
            .padding()
        }
        .background(Color.mmBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadMarkdownIfNeeded()
        }
    }

    private func loadMarkdownIfNeeded() {
        guard markdownText.isEmpty, loadErrorMessage == nil else { return }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md") else {
            loadErrorMessage = "\(title) 파일을 찾을 수 없습니다."
            return
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            markdownText = text
        } catch {
            loadErrorMessage = "\(title) 파일을 불러오는 중 오류가 발생했습니다."
        }
    }
}
