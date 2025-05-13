//
//  AdminTabbar.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//
import SwiftUI
import Foundation

struct AdminTabbar: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    // Add state for managing presentation of login screen
    @State private var navigateToLogin = false
    
    var body: some View {
        Group {
            if navigateToLogin {
                // When navigateToLogin is true, show the login screen
                ContentView()
                    .accessibilityHidden(false)
                    .accessibilityLabel("Login screen")
            } else {
                TabView(selection: $selectedTab) {
                    HomeViewAdmin()
                        .tag(0)
                        .tabItem {
                            Label("Dashboard", systemImage: "house")
                        }
                        .accessibilityLabel("Dashboard Tab")
                        .accessibilityHint("Navigates to admin dashboard")

                    BookViewAdmin()
                        .tag(1)
                        .tabItem {
                            Label("Books", systemImage: "book.closed")
                        }
                        .accessibilityLabel("Books Tab")
                        .accessibilityHint("Navigates to books section")

                    UsersViewAdmin()
                        .tag(2)
                        .tabItem {
                            Label("Users", systemImage: "person.2.fill")
                        }
                        .accessibilityLabel("Users Tab")
                        .accessibilityHint("Navigates to users list")

                    ManagePoliciesAdmin()
                        .tag(3)
                        .tabItem {
                            Label("Policies", systemImage: "document.badge.gearshape.fill")
                        }
                        .accessibilityLabel("Policies Tab")
                        .accessibilityHint("Navigates to manage library policies")
                    ThemeEditorView()
                        .tag(4)
                        .tabItem {
                            Label("Theme", systemImage: "eyedropper")
                        }
                        .accessibilityLabel("Theme Tab")
                        .accessibilityHint("Navigates to theme editor")
                }
                .accentColor(Color.primary(for: colorScheme))
                .toolbarBackground(Color.TabbarBackground(for: colorScheme), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))) { _ in
                    print("Received logout notification in AdminTabbar")
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

struct AdminTabbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AdminTabbar()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            AdminTabbar()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
