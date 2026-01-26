//
//  ReverseGeocodeRepositoryImpl.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

final class ReverseGeocodeRepositoryImpl: ReverseGeocodeRepository {
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

    func fetchAddress(longitude: Double, latitude: Double) async throws -> ReverseGeocodeResponseDTO {
        let endpoint = ReverseGeocodeEndpoint(
            apiKeyId: apiKeyId,
            apiKey: apiKey,
            longitude: longitude,
            latitude: latitude
        )

        return try await client.request(
            endpoint: endpoint,
            responseType: ReverseGeocodeResponseDTO.self
        )
    }
}
