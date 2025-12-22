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
}
