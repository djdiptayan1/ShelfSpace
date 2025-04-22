//
//  AdminTabbar.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//
import SwiftUI

struct AdminTabbar: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeViewAdmin()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("Dashboard")
                }

            UsersViewAdmin()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Users")
                }

            ManagePoliciesAdmin()
                .tabItem {
                    Image(systemName: "document.badge.gearshape.fill")
                    Text("Policies")
                }
        }
        .accentColor(Color.primary(for: colorScheme))
        .onAppear {
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

// Placeholder Views
struct HomeViewAdmin: View {
    var body: some View {
        NavigationView {
            Text("Home Screen Admin")
                .navigationTitle("Home")
        }
    }
}

struct UsersViewAdmin: View {
    var body: some View {
        NavigationView {
            Text("Users Screen Admin")
                .navigationTitle("Users")
        }
    }
}

struct ManagePoliciesAdmin: View {
    var body: some View {
        NavigationView {
            Text("Manage policies Screen Admin")
                .navigationTitle("Manage")
        }
    }
}

#Preview {
    AdminTabbar()
}
