//
//  NaverGeocodingRepositoryImpl.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

final class NaverGeocodingRepositoryImpl: GeocodingRepository {
    private let client: NetworkClient
    private let apiKeyId: String
    private let apiKey: String

    init(
        client: NetworkClient,
        apiKeyId: String = AppConfig.naverGeocodingApiKeyId,
        apiKey: String = AppConfig.naverGeocodingApiKey
    ) {
        self.client = client
        self.apiKeyId = apiKeyId
        self.apiKey = apiKey
    }

    func geocode(address: String) async throws -> Coordinate {
        let endpoint = NaverGeocodeEndpoint(
            query: address,
            apiKeyId: apiKeyId,
            apiKey: apiKey
        )

        let dto = try await client.request(
            endpoint: endpoint,
            responseType: NaverGeocodeResponseDTO.self
        )

        guard let first = dto.addresses.first,
              let longtitude = Double(first.x),
              let latitude = Double(first.y) else {
            throw DomainError.notFound
        }

        return Coordinate(latitude: latitude, longitude: longtitude)
    }
}
