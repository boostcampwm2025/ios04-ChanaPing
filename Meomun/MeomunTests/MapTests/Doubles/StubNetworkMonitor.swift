//
//  StubNetworkMonitor.swift
//  Meomun
//
//  Created by MinwooJe on 1/30/26.
//

@testable import Meomun

final class StubNetworkMonitor: NetworkMonitoring {
    let isConnected: Bool

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }

    func checkConnection() -> Bool {
        return isConnected
    }
}
