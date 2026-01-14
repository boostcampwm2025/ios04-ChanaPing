//
//  Place.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

struct Place: Identifiable, Sendable {
    let id: PlaceID
    let name: String
    let location: Location
}

extension Place: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
