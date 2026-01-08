//
//  DomainError.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

enum DomainError: Error, Sendable, Equatable {
    case networkUnavailable
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case server
    case invalidRequest
    case decoding
    case unknown
}
