//
//  NaverGeocodeEndpoint.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

import Foundation

struct NaverGeocodeEndpoint: Endpoint {
    let query: String
    let apiKeyId: String
    let apiKey: String

    var baseURL: String { "https://naveropenapi.apigw.ntruss.com" }
    var path: String { "/map-geocode/v2/geocode" }
    var method: HTTPMethod { .get }

    var headers: [String: String]? {
        [
            "X-NCP-APIGW-API-KEY-ID": apiKeyId,
            "X-NCP-APIGW-API-KEY": apiKey
        ]
    }

    var body: Data? { nil }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "query", value: query)
        ]
    }
}
