//
//  ResolvePlaceLocationUseCase.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

import Foundation

protocol ResolvePlaceLocationUseCaseProtocol: Sendable {
    func execute(address: String) async throws -> Coordinate
}

final class ResolvePlaceLocationUseCase: ResolvePlaceLocationUseCaseProtocol {
    private let repository: GeocodingRepository

    init(repository: GeocodingRepository) {
        self.repository = repository
    }

    func execute(address: String) async throws -> Coordinate {
        try await repository.geocode(address: address)
    }
}
