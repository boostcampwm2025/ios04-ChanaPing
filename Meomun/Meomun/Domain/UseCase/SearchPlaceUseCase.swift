//
//  SearchPlaceUseCase.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

import Foundation

protocol SearchPlaceUseCaseProtocol {
    func execute(query: String, near: Coordinate) async throws -> [Place]
}

final class SearchPlaceUseCase: SearchPlaceUseCaseProtocol {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func execute(query: String, near: Coordinate) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 1 else { return [] }
        return try await repository.searchPlace(query: trimmed, near: near)
    }
}
