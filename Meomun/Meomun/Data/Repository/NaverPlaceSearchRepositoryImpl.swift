//
//  NaverPlaceSearchRepositoryImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

final class NaverPlaceSearchRepositoryImpl: PlaceRepository {
    private let network: NetworkClient
    private let clientId: String
    private let clientSecret: String

    init(
        network: NetworkClient,
        clientId: String = AppConfig.naverClientId,
        clientSecret: String = AppConfig.naverClientSecret
    ) {
        self.network = network
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    func searchPlace(query: String) async throws -> [NaverLocalItemDTO] {
        let endpoint = NaverLocalSearchEndpoint(
            query: query,
            clientId: clientId,
            clientSecret: clientSecret
        )

        let dto = try await network.request(
            endpoint: endpoint,
            responseType: NaverLocalSearchResponseDTO.self
        )

        return dto.items
    }
}
