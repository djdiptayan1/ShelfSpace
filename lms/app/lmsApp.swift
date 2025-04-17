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
    @Environment(\.colorScheme) private var colorScheme
    
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
