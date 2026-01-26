//
//  NetworkMonitor.swift
//  Meomun
//
//  Created by MinwooJe on 1/26/26.
//

import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isConnected: Bool = false
    private let lock = NSLock()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.lock.lock()
            defer { self?.lock.unlock() }
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// 즉시 네트워크 연결 상태를 체크합니다 (동기)
    func checkConnection() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return monitor.currentPath.status == .satisfied
    }
}
