//
//  librarianTabbar.swift
//  lms
//
//  Created by Navdeep on 24/04/25.
//

import Foundation
import SwiftUI

struct UserTabbar: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject private var appState: AppState
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ExploreBooksView()
                .tag(1)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
            
            BookCollectionuser()
                .tag(2)
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("My Books")
                }
            
        }
        .accentColor(Color.primary(for: colorScheme))
        .toolbarBackground(Color.TabbarBackground(for: colorScheme), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(colorScheme, for: .tabBar)
    }
}
#Preview {
    UserTabbar().environmentObject(AppState())
}
