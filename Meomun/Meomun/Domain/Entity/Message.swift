//
//  Message.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct Message: Identifiable, Sendable {
    let id: MessageID
    let author: User
    let timestamp: Date

    let content: String
    let coordinate: Coordinate
    let placeTag: Place?
}
