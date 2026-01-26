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

    func fromAddressSuffixStart() -> String {
        // 시작점 후보
        let markers = ["읍", "면", "리", "가", "로", "길"]

        let tokens = self.split(separator: " ").map(String.init)
        guard tokens.isEmpty == false else { return self }

        // 토큰 중에 marker로 끝나는 단어를 찾는다.
        if let index = tokens.firstIndex(where: { token in
            markers.contains(where: { token.hasSuffix($0) })
        }) {
            return tokens[index...].joined(separator: " ")
        }

        // 못 찾으면 fallback: 뒤 3개
        return tokens.suffix(min(3, tokens.count)).joined(separator: " ")
    }
}
