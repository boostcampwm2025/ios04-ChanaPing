//
//  SupabaseLogin.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

import Foundation
import Supabase

enum SupabaseAuthBootstrapper {
    static func signInAnonymouslyIfNeeded() async {
        let client = SupabaseService.shared.client

        do {
            // 세션이 이미 있으면(로그인 상태/익명 포함) 재로그인 불필요
            _ = try await client.auth.session
            #if DEBUG
            AppLog.debug("[Supabase] Existing session found. Skip anonymous sign-in.", category: .login)
            #endif
            return
        } catch {
            // 세션이 없거나 복구 실패 → 익명 로그인 시도
            do {
                _ = try await client.auth.signInAnonymously()
                #if DEBUG
                AppLog.debug("[Supabase] Signed in anonymously.", category: .login)
                #endif
            } catch {
                // 이 경우 이후 Edge Function 호출은 401이 날 수밖에 없음
                AppLog.error("[Supabase] Anonymous sign-in failed:", category: .login, error: error)
            }
        }
    }

    // 운영 빌드에서는 토큰 전체를 절대 로그로 남기지 말아야 함
    static func logCurrentAccessToken(prefixCount: Int = 16) async {
        let client = SupabaseService.shared.client

        do {
            let session = try await client.auth.session
            let token = session.accessToken

            #if DEBUG
            let prefix = token.prefix(prefixCount)
            AppLog.debug("[Supabase] Access token prefix(\(prefixCount)): \(prefix)", category: .login)
            AppLog.debug("[Supabase] Access token FULL: \(token)", category: .login)
            #endif
        } catch {
            AppLog.error("[Supabase] Failed to load session: ", category: .login, error: error)
        }
    }
}
