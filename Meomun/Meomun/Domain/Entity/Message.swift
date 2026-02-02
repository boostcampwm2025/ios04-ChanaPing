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
    let address: String
    let placeTag: Place?
}

extension Message {
    var displayLocationName: String {
        // placeTag가 있다면 name
        if let tagName = placeTag?.name, !tagName.isEmpty {
            return tagName
        } else {
            return address.fromAddressSuffixStart()
        }
    }

    var displayDateString: String {
        return MessageTimestampFormatter().string(from: createdAt)
    }

    var displayDateTimeString: String {
        return MessageTimestampFormatter(style: .dateTime).string(from: createdAt)
    }
}
