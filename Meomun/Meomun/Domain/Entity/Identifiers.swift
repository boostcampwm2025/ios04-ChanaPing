//
//  Identifiers.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct MessageID: Hashable, Sendable { public let value: UUID }
struct PlaceID: Hashable, Sendable { public let value: UUID }
struct UserID: Hashable, Sendable { public let value: UUID }
