//
//  NetworkMonitor.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import Network
import SwiftUI
import OSLog

extension Logger {
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
}

/// Monitors network connectivity changes
@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = false
    private var wasConnected: Bool = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let isNowConnected = path.status == .satisfied

            Task { @MainActor in
                let previouslyConnected = self.wasConnected
                self.isConnected = isNowConnected
                self.wasConnected = isNowConnected

                if !previouslyConnected && isNowConnected {
                    Logger.network.info("✅ Network connection restored")
                } else if previouslyConnected && !isNowConnected {
                    Logger.network.info("❌ Network connection lost")
                }
            }
        }

        monitor.start(queue: queue)
        Logger.network.info("📡 Network monitoring started")
    }

    deinit {
        monitor.cancel()
        Logger.network.info("📡 Network monitoring stopped")
    }
}
