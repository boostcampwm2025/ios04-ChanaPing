//
//  PlaceRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

protocol PlaceRepository: Sendable {
    func searchPlace(query: String, start: Int) async throws -> [NaverLocalItemDTO]
}
