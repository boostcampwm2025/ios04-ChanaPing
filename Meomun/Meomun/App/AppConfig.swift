//
//  AppConfig.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import Foundation

enum AppConfig {
    // Supabase 설정
    static var supabaseProjectRef: String {
        guard let url = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_PROJECT_REF"
        ) as? String else {
            fatalError("SUPABASE_PROJECT_REF not found")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_ANON_KEY"
        ) as? String else {
            fatalError("SUPABASE_ANON_KEY not found")
        }
        return key
    }
}
