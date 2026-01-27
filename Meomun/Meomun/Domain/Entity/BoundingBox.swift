//
//  BoundingBox.swift
//  Meomun
//
//  Created by Hayeon Park on 1/27/26.
//

struct BoundingBox: Equatable, Sendable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
}

extension BoundingBox {
    func expanded(by ratio: Double) -> BoundingBox {
        let latitudeSpan = maxLatitude - minLatitude
        let longitudeSpan = maxLongitude - minLongitude

        let latitudePadding = latitudeSpan * ratio
        let longitudePadding = longitudeSpan * ratio

        return BoundingBox(
            minLatitude: minLatitude - latitudePadding,
            maxLatitude: maxLatitude + latitudePadding,
            minLongitude: minLongitude - longitudePadding,
            maxLongitude: maxLongitude + longitudePadding
        )
    }
}
