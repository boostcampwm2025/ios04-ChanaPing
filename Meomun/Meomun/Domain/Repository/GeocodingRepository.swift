//
//  GeocodingRepository.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

protocol GeocodingRepository {
    func geocode(address: String) async throws -> Coordinate
}
