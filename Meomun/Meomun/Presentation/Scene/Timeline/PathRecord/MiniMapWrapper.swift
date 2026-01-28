//
//  MiniMapWrapper.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import SwiftUI

struct MiniMapWrapper: UIViewControllerRepresentable {
    private let messages: [Message]

    init(messages: [Message]) {
        self.messages = messages
    }

    func makeUIViewController(context: Context) -> MiniMapViewController {
        MiniMapViewController()
    }

    func updateUIViewController(_ uiViewController: MiniMapViewController, context: Context) {
    }
}
