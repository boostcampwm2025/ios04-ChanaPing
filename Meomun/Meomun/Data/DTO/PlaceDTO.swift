//
//  PlaceDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

struct PlaceDTO: Codable, Equatable {
    let placeId: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
}
