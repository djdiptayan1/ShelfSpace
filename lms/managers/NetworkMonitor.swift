//
//  NetworkMonitor.swift
//  lms
//
//  Created by Diptayan Jash on 21/04/25.
//

import Foundation
import Network
import Combine
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    // Changed from private to internal for preview access
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
                
                let status = self?.isConnected == true ? "Connected" : "Disconnected"
                let type = self?.connectionType
                print("Network status changed: \(status), type: \(String(describing: type))")

                NotificationCenter.default.post(
                    name: Notification.Name("NetworkStatusChanged"),
                    object: self,
                    userInfo: ["connected": self?.isConnected ?? false]
                )
            }
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    #if DEBUG
    // For preview purposes only
    func setStatus(connected: Bool, type: ConnectionType) {
        isConnected = connected
        connectionType = type
    }
    #endif
}

struct NetworkStatusIndicator: View {
    // Observe the shared NetworkMonitor instance
    @ObservedObject private var monitor: NetworkMonitor
    
    init(monitor: NetworkMonitor = NetworkMonitor.shared) {
        self.monitor = monitor
    }

    // Computed properties for dynamic UI elements
    private var statusIcon: String {
        guard monitor.isConnected else {
            // Use a clear icon for disconnection
            return "wifi.slash"
        }
        // Use specific icons for connection types when connected
        switch monitor.connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            // Use a modern cellular icon
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            // Use a network or computer icon for ethernet
            return "network" // Alternative: "desktopcomputer"
        case .unknown:
            // Use a generic connected or question mark icon if type is unknown
            return "questionmark.circle" // Alternative: "wifi" as a default connected state
        }
    }

    private var statusText: String {
        monitor.isConnected ? "Connected" : "Offline"
    }

    private var statusColor: Color {
        monitor.isConnected ? .green : .secondary // Green for connected, subtle gray for offline
    }

    private var connectionTypeText: String? {
        guard monitor.isConnected else { return nil }

        switch monitor.connectionType {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return nil // Don't show type if unknown
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Status Icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 16, weight: .medium)) // Slightly larger, medium weight icon

            // Status Text (Main)
            Text(statusText)
                .font(.system(.footnote, design: .rounded).weight(.medium)) // Rounded, medium weight footnote
                .foregroundColor(.primary) // Adapts to light/dark mode

            // Optional: Connection Type Text (Subtle)
            if let connectionType = connectionTypeText {
                Text("(\(connectionType))")
                    .font(.system(.caption2, design: .rounded)) // Smaller, rounded caption
                    .foregroundColor(.secondary) // Less prominent color
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        // Use an adaptive background material for a modern look
        .background(.ultraThinMaterial)
        // Clip to a capsule shape
        .clipShape(Capsule())
        // Add a subtle overlay border matching the status color
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(0.6), lineWidth: 1)
        )
        // Animate changes smoothly
        .animation(.easeInOut(duration: 0.3), value: monitor.isConnected)
        .animation(.easeInOut(duration: 0.3), value: monitor.connectionType)
        // Add a subtle shadow for depth (optional)
        // .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Preview Provider

struct NetworkStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default state from NetworkMonitor.shared
            NetworkStatusIndicator()
                .previewDisplayName("Default State")

            // Connected Wi-Fi state
            createPreview(connected: true, type: .wifi)
                .previewDisplayName("Connected Wi-Fi")
            
            // Connected Cellular state
            createPreview(connected: true, type: .cellular)
                .previewDisplayName("Connected Cellular")
            
            // Disconnected state
            createPreview(connected: false, type: .unknown)
                .previewDisplayName("Offline")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    // Helper method to create preview views with different states
    private static func createPreview(connected: Bool, type: NetworkMonitor.ConnectionType) -> some View {
        let monitor = NetworkMonitor()
        monitor.setStatus(connected: connected, type: type)
        return NetworkStatusIndicator(monitor: monitor)
    }
}
