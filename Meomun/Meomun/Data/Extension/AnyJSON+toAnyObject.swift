//
//  AnyJSON+toAnyObject.swift
//  Meomun
//
//  Created by 지연 on 1/20/26.
//

import Foundation
import Supabase

extension AnyJSON {
    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    var objectValue: [String: AnyJSON]? {
        guard case let .object(dictionary) = self else { return nil }
        return dictionary
    }

    func toAnyObject() -> Any {
        switch self {
        case .string(let value):
            return value

        case .double(let value):
            return value

        case .integer(let value):
            return value

        case .bool(let value):
            return value

        case .null:
            return NSNull()

        case .array(let elements):
            return elements.map { $0.toAnyObject() }

        case .object(let dictionary):
            return dictionary.mapValues { $0.toAnyObject() }
        }
    }
}

extension Dictionary where Key == String, Value == AnyJSON {
    func toAnyObject() -> [String: Any] {
        mapValues { $0.toAnyObject() }
    }
}
