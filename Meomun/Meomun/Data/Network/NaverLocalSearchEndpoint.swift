//
//  NaverLocalSearchEndpoint.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

import Foundation

struct NaverLocalSearchEndpoint: Endpoint {
    let query: String
    let display: Int
    let start: Int
    let sort: String

    private let clientId: String
    private let clientSecret: String

    init(
        query: String,
        display: Int = 5,   // 공식문서상 5가 최댓값
        start: Int = 1,
        sort: String = "random",
        clientId: String,
        clientSecret: String
    ) {
        self.query = query
        self.display = display
        self.start = start
        self.sort = sort
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    var baseURL: String { "https://openapi.naver.com" }
    var path: String { "/v1/search/local.json" }
    var method: HTTPMethod { .get }
    var body: Data? { nil }

    var headers: [String: String]? {
        [
            "X-Naver-Client-Id": clientId,
            "X-Naver-Client-Secret": clientSecret
        ]
    }

    var queryItems: [URLQueryItem]? {
        [
            .init(name: "query", value: query),
            .init(name: "display", value: "\(display)"),
            .init(name: "start", value: "\(start)"),
            .init(name: "sort", value: sort)
        ]
    }
}
