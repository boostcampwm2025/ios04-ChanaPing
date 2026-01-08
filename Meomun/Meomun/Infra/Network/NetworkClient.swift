//
//  NetworkClient.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

protocol NetworkClient {
    func request<T: Sendable & Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T
}

final class MockNetworkClient: NetworkClient {

    var result: Any?

    func request<T>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T where T : Sendable & Decodable {

        guard let value = result as? T else {
            throw NetworkError.unknown
        }

        return value
    }
}
