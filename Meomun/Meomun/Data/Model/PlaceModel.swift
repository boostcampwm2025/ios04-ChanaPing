//
//  PlaceModel.swift
//  Meomun
//
//  Created by Hayeon Park on 1/27/26.
//

import Foundation
import SwiftData

@Model
final class PlaceModel {
    @Attribute(.unique) var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String

    init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        address: String
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

extension PlaceModel {
    func toDomain() -> Place {
        .init(
            id: PlaceID(value: id),
            name: name,
            coordinate: .init(
                latitude: latitude,
                longitude: longitude
            ),
            address: address
        )
    }

    func toDTO() -> PlaceDTO {
        .init(
            placeId: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            address: address
        )
    }
}
