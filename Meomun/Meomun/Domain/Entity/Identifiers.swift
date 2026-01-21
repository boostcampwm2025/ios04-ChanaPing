//
//  Identifiers.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct MessageID: Hashable, Sendable {
    let value: UUID
}

struct PlaceID: Hashable, Sendable {
    let value: String
}
