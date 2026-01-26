//
//  ReverseGeocodeEndpoint.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

import Foundation

struct ReverseGeocodeEndpoint: Endpoint {
    let baseURL: String = "https://maps.apigw.ntruss.com"
    let path: String = "/map-reversegeocode/v2/gc"
    let method: HTTPMethod = .get
    let body: Data? = nil

    let apiKeyId: String
    let apiKey: String

    let longitude: Double
    let latitude: Double

    var headers: [String: String]? {
        [
            "x-ncp-apigw-api-key-id": apiKeyId,
            "x-ncp-apigw-api-key": apiKey,
            "Accept": "application/json"
        ]
    }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "request", value: "coordsToaddr"),
            URLQueryItem(name: "coords", value: "\(longitude),\(latitude)"),
            URLQueryItem(name: "orders", value: "roadaddr,addr"),
            URLQueryItem(name: "output", value: "json")
        ]
    }
}
