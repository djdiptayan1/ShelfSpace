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
                .tag(1)
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("My Books")
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

//struct HomeViewUser: View {
//    var body: some View {
//        NavigationView {
//            Text("Home Screen user")
//                .navigationTitle("Home")
//        }
//    }
//}

#Preview {
    UserTabbar()
}
