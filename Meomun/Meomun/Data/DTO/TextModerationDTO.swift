//
//  TextModerationDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/15/26.
//

enum ModerationDecision: String, Codable {
    case ALLOW, REVIEW, BLOCK
    case UNKNOWN

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = ModerationDecision(rawValue: value) ?? .UNKNOWN
    }
}

enum ModerationLabel: String, Codable, CaseIterable {
    case harassment = "HARASSMENT"
    case hate = "HATE"
    case violence = "VIOLENCE"
    case sexual = "SEXUAL"
    case selfHarm = "SELF_HARM"
    case illegal = "ILLEGAL"
    case profanity = "PROFANITY"
    case other = "OTHER"
}

struct TextModerationResponse: Decodable, Equatable {
    let decision: ModerationDecision
    let labels: [ModerationLabel]
    let score: Int
    let reason: String
}
