//
//  NetworkMonitor.swift
//  Meomun
//
//  Created by MinwooJe on 1/26/26.
//

import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// 즉시 네트워크 연결 상태를 체크합니다 (동기)
    func checkConnection() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
}
