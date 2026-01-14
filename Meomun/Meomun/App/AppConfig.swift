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

    static var supabaseURL: URL {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PROJECT_ID") as? String else {
            fatalError("SUPABASE_PROJECT_ID not found")
        }

        guard let url = URL(string: "https://\(key).supabase.co") else {
            fatalError("SUPABASE_URL의 형식이 올바르지 않습니다: https://\(key).supabase.co")
        }

        return url
    }

    static var supabaseKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_KEY"
        ) as? String else {
            fatalError("SUPABASE_KEY not found")
        }
        return key
    }
}
