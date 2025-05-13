//
//  ContentView.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme    
    var body: some View {
        LoginView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}


