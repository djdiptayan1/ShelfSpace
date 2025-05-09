//
//  lmsApp.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//

import SwiftUI

@main
struct lmsApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var appState = AppState()
    @Environment(\.colorScheme) private var colorScheme

    init() {
        _ = NetworkMonitor.shared
        // Request notification permission on app launch
        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
//            ContentView()
            SplashScreenView()
                .environmentObject(themeManager)
                .environmentObject(appState)
                .onChange(of: colorScheme) { newColorScheme in
                    themeManager.update(with: newColorScheme)
                }
        }
    }
}
