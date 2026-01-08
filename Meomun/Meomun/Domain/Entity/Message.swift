//
//  Message.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation

struct Message: Identifiable, Sendable {
    let id: MessageID
    let authorID: UserID
    let createdAt: Date

    let content: String
    let location: Location
    let placeTag: Place?

    func isRecent(recentInterval: TimeInterval = 60 * 20) -> Bool {
        Date().timeIntervalSince(createdAt) <= recentInterval
    }
}
