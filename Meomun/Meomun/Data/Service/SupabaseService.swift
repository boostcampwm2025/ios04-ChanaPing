//
//  SupabaseService.swift
//  Meomun
//
//  Created by MinwooJe on 2/2/26.
//

import Foundation

protocol SupabaseService: Sendable {
    func searchPlace(
        query: String,
        sort: String
    ) async throws -> [NaverLocalItemDTO]
    func fetchAddress(longitude: Double, latitude: Double) async throws -> ReverseGeocodeResponseDTO
}

final class SupabaseServiceImpl: SupabaseService {
    private let client: NetworkClient
    private let baseURL: String = "https://\(AppConfig.supabaseProjectRef).supabase.co"

    init(network: NetworkClient) {
        self.client = network
    }

    func searchPlace(
        query: String,
        sort: String = "random"
    ) async throws -> [NaverLocalItemDTO] {
        // Naver API 제약: start, display는 각각 1, 5로만 고정됨.
        let endpoint = DefaultEndpoint(
            baseURL: baseURL,
            path: "/functions/v1/naver-local-search",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(AppConfig.supabaseAnonKey)"
            ],
            queryItems: [
                .init(name: "query", value: query),
                .init(name: "display", value: "\(5)"),
                .init(name: "start", value: "\(1)"),
                .init(name: "sort", value: "random")
            ]
        )

        do {
            let dto = try await client.request(
                endpoint: endpoint,
                responseType: NaverLocalSearchResponseDTO.self
            )
            return dto.items
        } catch let error as NetworkError {
            if case let .serverError(statusCode, data) = error,
               let backendError = BackendServiceError.from(statusCode: statusCode, data: data) {
                throw backendError
            }
            throw error
        }
    }

    func fetchAddress(longitude: Double, latitude: Double) async throws -> ReverseGeocodeResponseDTO {
        let endpoint = DefaultEndpoint(
            baseURL: baseURL,
            path: "/functions/v1/naver-reverse-geocode",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(AppConfig.supabaseAnonKey)"
            ],
            queryItems: [
                .init(name: "longitude", value: "\(longitude)"),
                .init(name: "latitude", value: "\(latitude)")
            ]
        )

        do {
            return try await client.request(
                endpoint: endpoint,
                responseType: ReverseGeocodeResponseDTO.self
            )
        } catch let error as NetworkError {
            if case let .serverError(statusCode, data) = error,
               let backendError = BackendServiceError.from(statusCode: statusCode, data: data) {
                throw backendError
            }
            throw error
        }
    }
}
