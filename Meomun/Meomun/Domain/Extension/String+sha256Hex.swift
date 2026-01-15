//
//  String+sha256Hex.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import Foundation
import CryptoKit

extension String {
    func sha256Hex() -> String {
        let hashed = SHA256.hash(data: Data(self.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    /// 장소 ID 생성을 위한 정규화 키
    func normalizedKey() -> String {
        self
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[^0-9a-z가-힣]", with: "", options: .regularExpression)
    }
}
