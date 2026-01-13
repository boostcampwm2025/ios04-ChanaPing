//
//  NaverGeocodingRepositoryImpl.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

final class NaverGeocodingRepositoryImpl: GeocodingRepository {
    private let network: NetworkClient
    private let apiKeyId: String
    private let apiKey: String

    init(
        network: NetworkClient,
        apiKeyId: String = AppConfig.naverGeocodingApiKeyId,
        apiKey: String = AppConfig.naverGeocodingApiKey
    ) {
        self.network = network
        self.apiKeyId = apiKeyId
        self.apiKey = apiKey
    }

    func geocode(address: String) async throws -> Coordinate {
        let endpoint = NaverGeocodeEndpoint(
            query: address,
            apiKeyId: apiKeyId,
            apiKey: apiKey
        )

        let dto = try await network.request(
            endpoint: endpoint,
            responseType: NaverGeocodeResponseDTO.self
        )

        guard let first = dto.addresses.first,
              let longitude = Double(first.x),
              let latitude = Double(first.y) else {
            throw DomainError.notFound
        }

        return Coordinate(latitude: latitude, longitude: longitude)
    }
}
