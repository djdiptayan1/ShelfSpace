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
                .tag(0)
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            BookViewAdmin()
                .tag(1)
                .tabItem {
                    Label("Books", systemImage: "book.closed")
                }

            UsersViewAdmin()
                .tag(2)
                .tabItem {
                    Label("Users", systemImage: "person.2.fill")
                }

            ManagePoliciesAdmin()
                .tag(3)
                .tabItem {
                    Label("Policies", systemImage: "document.badge.gearshape.fill")
                }
        }
        .accentColor(Color.primary(for: colorScheme))
        .toolbarBackground(Color.TabbarBackground(for: colorScheme), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(colorScheme, for: .tabBar)
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
