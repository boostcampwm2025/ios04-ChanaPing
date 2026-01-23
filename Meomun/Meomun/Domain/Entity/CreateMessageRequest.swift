//
//  CreateMessageRequest.swift
//  Meomun
//
//  Created by MinwooJe on 1/21/26.
//

struct CreateMessageRequest: Equatable {
    let content: String
    let coordinate: Coordinate
    let address: String
    let place: Place?
}
