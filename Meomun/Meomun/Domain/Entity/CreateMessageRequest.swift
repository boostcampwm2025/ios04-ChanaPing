//
//  CreateMessageRequest.swift
//  Meomun
//
//  Created by Claude on 1/21/26.
//

struct CreateMessageRequest: Equatable {
    let content: String
    let coordinate: Coordinate
    let place: Place?
}
