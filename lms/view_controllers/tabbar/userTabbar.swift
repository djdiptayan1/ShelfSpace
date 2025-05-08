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

    // Add state for managing presentation of login screen
    @State private var navigateToLogin = false

    var body: some View {
        Group {
            if navigateToLogin {
                // When navigateToLogin is true, show the login screen
                ContentView()
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .accessibilityLabel("Home Tab")

                    ExploreBooksView()
                        .tag(1)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Explore")
                        }
                        .accessibilityLabel("Explore Tab")

                    BookCollectionuser()
                        .tag(2)
                        .tabItem {
                            Image(systemName: "books.vertical.fill")
                            Text("My Books")
                        }
                        .accessibilityLabel("My Books Tab")

                    FolioView()
                        .tag(3)
                        .tabItem {
                            Image(systemName: "apple.intelligence")
                            Text("Folio")
                        }
                        .accessibilityLabel("Mood Journey Tab")
                }
                .accentColor(Color.primary(for: colorScheme))
                .toolbarBackground(Color.TabbarBackground(for: colorScheme), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .onReceive(
                    NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))
                ) { _ in
                    print("Received logout notification in UserTabbar")
                    // Set navigateToLogin to true when we receive the logout notification
                    navigateToLogin = true
                }
            }
        }
        .onAppear {
            // Check if we're logged in when view appears
            if !appState.isLoggedIn {
                navigateToLogin = true
            }
        }
        .onChange(of: appState.isLoggedIn) { isLoggedIn in
            // React to changes in the login state
            if !isLoggedIn {
                navigateToLogin = true
            }
        }
    }
}

#Preview {
    UserTabbar().environmentObject(AppState())
}
