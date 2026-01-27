//
//  NetworkError.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

enum NetworkError: Error {
    case noConnection
    case invalidURL
    case transportError(Error)
    case serverError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case unknown
}
