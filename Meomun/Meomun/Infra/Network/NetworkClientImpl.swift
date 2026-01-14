//
//  NetworkClientImpl.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

final class NetworkClientImpl: NetworkClient {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Sendable & Decodable>(
        endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {

        let request = try endpoint.makeURLRequest()

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(
                    statusCode: httpResponse.statusCode,
                    data: data
                )
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw NetworkError.decodingError(error)
            }

        } catch let networkError as NetworkError {
            throw networkError
        } catch {
            throw NetworkError.transportError(error)
        }
    }
}
