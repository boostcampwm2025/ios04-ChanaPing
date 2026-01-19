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

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case latitude
        case longitude
        case address
    }
}

// MARK: - Mapping

extension PlaceDTO {
    func toDomain() -> Place {
        Place(
            id: PlaceID(value: placeId),
            name: name,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            address: ""
        )
    }
}
