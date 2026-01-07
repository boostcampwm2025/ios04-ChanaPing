//
//  Message.swift
//  Meomun
//
//  Created by 지연 on 1/8/26.
//

import Foundation

struct Message {
    let id: UUID
    let author: User
    let timestamp: Date

    var content: String
    var coordinate: Coordinate
    var placeTag: Place?
}
