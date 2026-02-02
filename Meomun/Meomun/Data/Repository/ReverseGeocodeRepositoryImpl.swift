//
//  ReverseGeocodeRepositoryImpl.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

final class ReverseGeocodeRepositoryImpl: ReverseGeocodeRepository {
    private let remote: SupabaseService

    init(remote: SupabaseService) {
        self.remote = remote
    }

    func fetchAddress(longitude: Double, latitude: Double) async throws -> ReverseGeocodeResponseDTO {
        try await remote.fetchAddress(longitude: longitude, latitude: latitude)
    }
}
