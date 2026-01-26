//
//  UpdateMessageRequestDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/27/26.
//

import Foundation

struct UpdateMessageRequestDTO: Encodable, Equatable {
    let id: UUID
    let createAt: Date
    let content: String
    let latitude: Double
    let longitude: Double
    let address: String
    let place: PlaceDTO?
}
