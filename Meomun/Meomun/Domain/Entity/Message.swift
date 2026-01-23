//
//  Message.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation

struct Message: Identifiable, Sendable, Equatable {
    let id: MessageID
    let createdAt: Date
    let content: String
    let coordinate: Coordinate
    let address: String?
    let placeTag: Place?

    func isRecent(recentInterval: TimeInterval = 60 * 20) -> Bool {
        Date().timeIntervalSince(createdAt) <= recentInterval
    }
}

extension Message {
    var displayLocationName: String? {
        // placeTag가 있다면 name
        if let tagName = placeTag?.name, !tagName.isEmpty {
            return tagName
        }
        // 없다면 address (동부터? 그 뒤부터? 하여튼 포매팅)
        if let address, !address.isEmpty {
            return address
        }
        return nil
    }

    var displayDateString: String { // 같은 날이면 시간, 다른 날이면 날짜로 보여지게 하기
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter.string(from: createdAt)
    }
}
