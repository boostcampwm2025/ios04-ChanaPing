//
//  AppLog.swift
//  Meomun
//
//  Created by 지연 on 1/14/26.
//

import Foundation
import OSLog

enum LogCategory: String {
    case permission = "Permission"
    case network = "Network"
    case store = "Store"
    case useCase = "UseCase"
    case repository = "Repository"
    case location = "Location"
    case space = "Space"    // 3D 공간, Realitykit 관련
    case resource = "Resource"  // 모델, material, 에셋 로딩 관련
}

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Meomun"

    static func debug(
        _ message: String,
        category: LogCategory,
        file: String = #fileID,
        line: Int = #line
    ) {
        #if DEBUG
        logger(category).debug("\(prefix(file, line)) \(message)")
        #endif
    }

    static func info(
        _ message: String,
        category: LogCategory,
        file: String = #fileID,
        line: Int = #line
    ) {
        logger(category).info("\(prefix(file, line)) \(message)")
    }

    static func warn(
        _ message: String,
        category: LogCategory,
        file: String = #fileID,
        line: Int = #line
    ) {
        logger(category).warning("\(prefix(file, line)) \(message)")
    }

    static func error(
        _ message: String,
        category: LogCategory,
        error: Error? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        if let error {
            logger(category).error("\(prefix(file, line)) \(message) | error: \(String(describing: error))")
        } else {
            logger(category).error("\(prefix(file, line)) \(message)")
        }
    }

    // 서버 바디/디코딩 실패 디버깅용
    static func errorResponse(
        statusCode: Int,
        data: Data?,
        category: LogCategory,
        file: String = #fileID,
        line: Int = #line
    ) {
        #if DEBUG
        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
        logger(category).error("\(prefix(file, line)) status=\(statusCode) body=\(body)")
        #else
        logger(category).error("\(prefix(file, line)) status=\(statusCode)")
        #endif
    }

    private static func logger(_ category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    private static func prefix(_ file: String, _ line: Int) -> String {
        "[\(file):\(line)]"
    }
}
