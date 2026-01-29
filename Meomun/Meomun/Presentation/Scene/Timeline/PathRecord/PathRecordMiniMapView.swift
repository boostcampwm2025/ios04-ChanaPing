//
//  PathRecordMiniMapView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import SwiftUI

struct PathRecordMiniMapView: View {
    let messages: [Message]

    var body: some View {
        MiniMapWrapper(messages: messages)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    let messages: [Message] =  [
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-7 * 60),
            content: "[Case4] NoPlace 스택 메시지 1",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-30 * 60),
            content: "[Case4] NoPlace 스택 메시지 2",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        ),
        Message(
            id: MessageID(value: UUID()),
            createdAt: Date().addingTimeInterval(-15000 * 60),
            content: "[Case4] NoPlace 스택 메시지 3",
            coordinate: Coordinate.seoulCity,
            address: "가람로 109",
            placeTag: nil
        )
    ]

    PathRecordMiniMapView(messages: messages)
}
