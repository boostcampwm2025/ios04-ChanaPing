//
//  SuperbaseService.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let url = AppConfig.supabaseURL
        let key = AppConfig.supabaseKey

        let options = SupabaseClientOptions(
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: options
        )
    }
}
