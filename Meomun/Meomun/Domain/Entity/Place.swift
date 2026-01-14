//
//  Place.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

struct Place: Identifiable, Sendable, Hashable {
    let id: PlaceID
    let name: String
    let coordinate: Coordinate
    var address: String? = nil

    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
