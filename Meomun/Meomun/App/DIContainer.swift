//
//  DIContainer.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

final class DIContainer {
    private static var shared = DIContainer()

    private init() { }

    private var dependencies: [String: Any] = [:]

    static func register<T>(_ dependency: T) {
        shared.register(dependency)
    }

    static func resolve<T>() -> T? {
        shared.resolve()
    }

    private func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency as Any
    }

    private func resolve<T>() -> T? {
        let key = String(describing: T.self)
        let dependency = dependencies[key] as? T

        guard let dependency else {
            AppLog.error("\(key) Dependency가 없음", category: .DIContainer)
            #if DEBUG
            assertionFailure("\(key) Dependency가 없음")
            #endif
            return nil
        }

        return dependency
    }
}
