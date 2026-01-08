//
//  PlaceRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

protocol PlaceRepository: Sendable {
    func searchPlace(query: String, near: Coordinate?, limit: Int?) async throws -> [Place]
}
