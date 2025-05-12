//
//  WebsocketManager.swift
//  lms
//
//  Created by dark on 12/05/25.
//

import Foundation
import Combine

struct SocketMessage<T:Codable>:Codable{
    let type: String
    let data :T
}


class WebSocketManager: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    
    static let shared = WebSocketManager()

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var pingTimer: Timer?

    // Use @Published if you want SwiftUI views to react to connection state
    let messagePublisher = PassthroughSubject<String, Never>()
    @Published var isConnected: Bool = false
    @Published var lastReceivedMessage: String? // Or a Decodable type

    private var jwtToken: String? // Store your JWT here (fetch from Keychain)
    private var serverURL: URL! // e.g., URL(string: "wss://yourserver.com/socket")!

    // Keep track if authentication message has been sent and acknowledged
    private var isAuthenticated = false
    private var authenticationPending = false

    override init() {
        super.init()
        // Initialize URLSession with this class as delegate
        // queue: nil means use a default background queue
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        setupWebSocket()
    }

    func configure(url: URL, token: String?) {
        self.serverURL = url
        self.jwtToken = token
    }

    // MARK: - Connection Management
    func setupWebSocket() {
        do{
            guard let url = URL(string: "ws://20.193.252.127:8080/socket") else { return }
            let token = try KeychainManager.shared.getToken() // Fetch your stored JWT
            self.configure(url: url, token: token)
            self.connect()
        } catch {
            print("Error setting up WebSocket: \(error)")
        }
    }

    func connect() {
        guard let token = jwtToken, !token.isEmpty else {
            print("WebSocket Error: JWT token is missing.")
            // Handle error: maybe user needs to log in again
            return
        }

        guard let url = serverURL else {
            print("WebSocket Error: Server URL not configured.")
            return
        }

        disconnect() // Ensure any existing connection is closed first

        // --- Strategy 1 Adaptation (Headers/Query Params) ---
        // If using headers:
         var request = URLRequest(url: url)
         request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         self.webSocketTask = urlSession.webSocketTask(with: request)

        // If using query params (ensure token is URL-safe encoded if needed):
//         var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//         components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "token", value: token)]
//         guard let urlWithToken = components.url else {
//             print("WebSocket Error: Could not create URL with token.")
//             return
//         }
//         self.webSocketTask = urlSession.webSocketTask(with: urlWithToken)
        // --- End Strategy 1 Adaptation ---

        // --- Using Strategy 2 (First Message) ---
        // Connect without sending token in handshake
//        self.webSocketTask = urlSession.webSocketTask(with: url)
        // --- End Strategy 2 ---

        print("WebSocket: Connecting to \(url)...")
        self.listen() // Start listening for messages
        self.webSocketTask?.resume() // Initiate the connection
        self.schedulePing() // Start keep-alive pings
    }

    func disconnect() {
        print("WebSocket: Disconnecting...")
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isAuthenticated = false
        authenticationPending = false
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }

    // MARK: - Message Handling

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("WebSocket Error: Failed to receive message: \(error.localizedDescription)")
                self.handleConnectionError(error)
                // Consider attempting reconnection here after a delay

            case .success(let message):
                switch message {
                case .string(let text):
                    print("WebSocket: Received text message.")
                    self.handleReceivedText(text)

                case .data(let data):
                    print("WebSocket: Received binary data: \(data.count) bytes")
                    // Handle binary data if needed
                    if let text = String(data: data, encoding: .utf8) {
                         self.handleReceivedText(text) // Attempt to decode as text too
                    }
                @unknown default:
                    print("WebSocket Warning: Received unknown message type.")
                }
                // Continue listening for the next message
                self.listen()
            }
        }
    }

    private func handleReceivedText(_ text: String) {
        print("WebSocket RX: \(text)")
        // --- Strategy 2: Handle Auth Response ---
        if authenticationPending {
            // Naive check: Assume first message after sending auth is the ack
            // A robust server would send a specific success/failure message
            // e.g., {"type": "auth_success"} or {"type": "auth_failure", "reason": "..."}
            if text.lowercased().contains("authenticated") || text.lowercased().contains("auth_success") { // Example check
                 print("WebSocket: Authentication successful!")
                 isAuthenticated = true
                 authenticationPending = false
                 // Now safe to send other messages
                 DispatchQueue.main.async {
                     self.isConnected = true // Update UI state only after auth
                 }
            } else if text.lowercased().contains("auth_failure") {
                 print("WebSocket Error: Authentication failed by server.")
                 authenticationPending = false
                 // Server might close the connection, or we can close it now
                 disconnect()
            }
            // else: Wait for a specific auth confirmation message
            return // Don't process further until authenticated
        }
        // --- End Strategy 2 ---

        // If already authenticated (or not using first-message auth), process normally
        if isAuthenticated || /* Use this OR if using Strategy 1 -> */ true {
            DispatchQueue.main.async {
                 self.lastReceivedMessage = text
                 self.messagePublisher.send(text)
            }
        } else {
             print("WebSocket Warning: Received message before authentication completed.")
             // Ignore or handle based on your protocol
        }
    }

    func send(message: String) {
        guard isConnected || authenticationPending /* Allow sending auth message */ else {
            print("WebSocket Error: Cannot send message, not connected or authenticated.")
            return
        }

        guard let task = webSocketTask else {
            print("WebSocket Error: Task not available.")
            return
        }

        print("WebSocket TX: \(message)")
        task.send(.string(message)) { error in
            if let error = error {
                print("WebSocket Error: Failed to send message: \(error.localizedDescription)")
                // Handle potential connection issue
                self.handleConnectionError(error)
            }
        }
    }

    // --- Strategy 2: Send Authentication Message ---
    private func sendAuthentication() {
        guard let token = jwtToken, !authenticationPending, !isAuthenticated else {
            print("WebSocket: Auth not needed or already pending/done.")
            return
        }

        let authMessage = """
        {
          "type": "auth",
          "token": "\(token)"
        }
        """
        print("WebSocket: Sending authentication message...")
        authenticationPending = true // Mark that we're waiting for server ack
        send(message: authMessage)
    }
    // --- End Strategy 2 ---


    // MARK: - Keep-Alive Ping

    private func schedulePing() {
        pingTimer?.invalidate() // Cancel existing timer if any
        // Send a ping every 30 seconds, for example
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("WebSocket Error: Failed sending ping: \(error.localizedDescription)")
                // Assume connection might be dead
                self.handleConnectionError(error)
            } else {
                print("WebSocket: Ping sent successfully.")
            }
        }
    }

    // MARK: - URLSessionWebSocketDelegate Methods

    // Called when the connection is successfully established
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket: Connection Established (Protocol: \(String(describing: `protocol`)))")
        // --- Strategy 2: Send Auth Message on Connect ---
        //sendAuthentication()
        // --- End Strategy 2 ---

        // --- Strategy 1: Update state immediately ---
        // DispatchQueue.main.async {
        //     self.isConnected = true
        //     self.isAuthenticated = true // Assume auth happened during handshake
        // }
        // --- End Strategy 1 ---
    }

    // Called when the connection is closed
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason"
        print("WebSocket: Connection Closed (Code: \(closeCode.rawValue), Reason: \(reasonString))")
        pingTimer?.invalidate()
        pingTimer = nil
        isAuthenticated = false
        authenticationPending = false
        DispatchQueue.main.async {
            self.isConnected = false
        }
        // Consider implementing reconnection logic here
    }

    // Handle session-level errors (less common for WebSocket specifics)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
             print("WebSocket Error: URLSession task completed with error: \(error.localizedDescription)")
             handleConnectionError(error)
        } else {
             // Task completed normally (likely means disconnected gracefully)
             print("WebSocket: URLSession task completed without error.")
        }
    }

    // MARK: - Error Handling Helper

    private func handleConnectionError(_ error: Error) {
         // Check if error indicates a connection loss
         let nsError = error as NSError
         if nsError.domain == NSPOSIXErrorDomain || nsError.domain == URLError.errorDomain {
             print("WebSocket: Connection likely lost.")
             disconnect() // Ensure state is cleaned up
             // Optionally trigger reconnection attempt after a delay
         } else {
             print("WebSocket: Encountered non-connection error: \(error.localizedDescription)")
             // Handle other errors if necessary
         }
    }
}

// Example Usage (e.g., in a SwiftUI View or ViewModel)
// let webSocketManager = WebSocketManager()
//
// func setupWebSocket() {
//     guard let url = URL(string: "wss://yourserver.com/socket") else { return }
//     let token = KeychainManager.shared.getToken() // Fetch your stored JWT
//     webSocketManager.configure(url: url, token: token)
//     webSocketManager.connect()
// }
//
// func sendMessage() {
//     let myMessage = """
//     { "type": "chat", "content": "Hello from iOS!" }
//     """
//     webSocketManager.send(message: myMessage)
// }
//
// // Observe webSocketManager.isConnected and webSocketManager.lastReceivedMessage
