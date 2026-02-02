//
//  NaverPlaceSearchRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

final class NaverPlaceSearchRepositoryImpl: PlaceRepository {
    private let remote: SupabaseService

    init(remote: SupabaseService) {
        self.remote = remote
    }

    func searchPlace(query: String) async throws -> [NaverLocalItemDTO] {
        try await remote.searchPlace(query: query)
    }
}
