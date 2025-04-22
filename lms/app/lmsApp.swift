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
    @Environment(\.colorScheme) private var colorScheme

    init() {
        _ = NetworkMonitor.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .onChange(of: colorScheme) { newColorScheme in
                    themeManager.update(with: newColorScheme)
                }
        }
    }
}
