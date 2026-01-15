//
//  JSONDecoders+iso8601.swift
//  Meomun
//
//  Created by 지연 on 1/15/26.
//

import Foundation

enum JSONDecoders {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(ISO8601DateParser.decode)
        return decoder
    }()
}

enum ISO8601DateParser {
    private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        if let date = parse(dateString) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date: \(dateString)"
        )
    }

    private static func parse(_ dateString: String) -> Date? {
        fractionalSecondsFormatter.date(from: dateString)
        ?? plainFormatter.date(from: dateString)
    }
}
