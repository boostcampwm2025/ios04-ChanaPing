//
//  BackendServiceError.swift
//  Meomun
//
//  Created by MinwooJe on 2/2/26.
//

import Foundation

private struct SupabaseErrorResponse: Decodable {
    let error: String
    let message: String
    let statusCode: Int
}

/// 백엔드(Supabase 등) 또는 업스트림 API(네이버 등)에서 반환된 에러.
enum BackendServiceError: Error, Sendable {
    case serviceError(message: String, statusCode: Int)
    case upstreamAPIError(message: String, statusCode: Int)

    /// `NetworkError.serverError(statusCode:data:)`의 data를 파싱해 BackendError로 변환.
    /// Supabase 에러 형식이 아니면 nil 반환.
    static func from(statusCode: Int, data: Data?) -> BackendServiceError? {
        guard let data,
              let response = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) else {
            return nil
        }
        if response.error == "NaverAPIError" {
            return .upstreamAPIError(message: response.message, statusCode: response.statusCode)
        }
        return .serviceError(message: response.message, statusCode: response.statusCode)
    }
}
