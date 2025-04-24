//
//  ContentView.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LoginView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}


