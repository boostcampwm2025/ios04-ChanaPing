//
//  AppConfig.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import Foundation

enum AppConfig {
    static var naverAPIKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "NAVER_API_KEY"
        ) as? String else {
            fatalError("NAVER_API_KEY not found")
        }
        return key
    }

    static var naverClientId: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "NAVER_CLIENT_ID"
        ) as? String else {
            fatalError("NAVER_CLIENT_ID not found")
        }
        return key
    }

    static var naverClientSecret: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "NAVER_CLIENT_SECRET"
        ) as? String else {
            fatalError("NAVER_CLIENT_SECRET not found")
        }
        return key
    }

    static var naverGeocodingApiKeyId: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "X_NCP_APIGW_API_KEY_ID"
        ) as? String else {
            fatalError("X_NCP_APIGW_API_KEY_ID not found")
        }
        return key
    }

    static var naverGeocodingApiKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "X_NCP_APIGW_API_KEY"
        ) as? String else {
            fatalError("X_NCP_APIGW_API_KEY not found")
        }
        return key
    }
}
