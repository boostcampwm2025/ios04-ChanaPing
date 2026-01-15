//
//  PlaceTagDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

struct PlaceTagDTO: Encodable, Equatable {
    let id: String?
    let name: String?
    let coordinate: CoordinateDTO?
    let address: String?
}
