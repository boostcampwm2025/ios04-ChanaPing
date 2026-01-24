//
//  ReverseGeocodeRepository.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

protocol ReverseGeocodeRepository: Sendable {
    func fetchAddress(longitude: Double, latitude: Double) async throws -> ReverseGeocodeResponseDTO
}
