//
//  NetworkMonitor.swift
//  Meomun
//
//  Created by MinwooJe on 1/26/26.
//

import Combine
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private var isConnected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)

        // 초기 상태 설정
        isConnected = monitor.currentPath.status == .satisfied
    }

    deinit {
        monitor.cancel()
    }

    /// 즉시 네트워크 연결 상태를 체크합니다 (동기)
    func checkConnection() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
}
