//
//  librarianTabbar.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//

import Foundation
import SwiftUI

struct LibrarianTabbar: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var themeManager = ThemeManager()
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeViewlib()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Books")
                }

            UsersViewlib()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Users")
                }

            ManageViewlib()
                .tabItem {
                    Image(systemName: "tray.full.fill")
                    Text("Requests")
                }
        }
        .accentColor(Color.primary(for: colorScheme))
        .onAppear(){
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.TabbarBackground(for: colorScheme))
            
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(Color.text(for: colorScheme).opacity(0.6))
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.text(for: colorScheme).opacity(0.6))
            ]
            itemAppearance.selected.iconColor = UIColor(Color.primary(for: colorScheme))
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.primary(for: colorScheme))
            ]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

struct HomeViewlib: View {
    var body: some View {
        NavigationView {
            Text("Home Screen librarian")
                .navigationTitle("Home")
        }
    }
}

struct UsersViewlib: View {
    var body: some View {
        NavigationView {
            Text("Users Screen librarian")
                .navigationTitle("Users")
        }
    }
}

struct ManageViewlib: View {
    var body: some View {
        NavigationView {
            Text("Manage Screen librarian")
                .navigationTitle("Manage")
        }
    }
}

#Preview {
    LibrarianTabbar()
}
