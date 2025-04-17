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
        NavigationView {
            VStack(spacing: 20) {
                Text("Library Management System")
                    .font(.title)
                    .foregroundColor(.text(for: colorScheme))
                
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primary(for: colorScheme))
                
                Text("Welcome to your digital library")
                    .foregroundColor(.text(for: colorScheme))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background(for: colorScheme))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
