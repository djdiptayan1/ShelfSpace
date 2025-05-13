////
////  librarianTabbar.swift
////  lms
////
////  Created by Diptayan Jash on 18/04/25.
////
//
//import Foundation
//import NavigationBarLargeTitleItems
//import SwiftUI
//
//struct LibrarianTabbar: View {
//    @State private var selectedTab = 0
//
//    @Environment(\.colorScheme) private var colorScheme
//    @StateObject private var themeManager = ThemeManager()
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            HomeViewlib()
//                .tag(0)
//                .tabItem {
//                    Image(systemName: "book.closed")
//                    Text("Books")
//                }
//
//            UsersViewlib()
//                .tag(1)
//                .tabItem {
//                    Image(systemName: "person.2.fill")
//                    Text("Users")
//                }
//
//            ManageViewlib()
//                .tag(2)
//                .tabItem {
//                    Image(systemName: "tray.full.fill")
//                    Text("Requests")
//                }
//        }
//        .accentColor(Color.primary(for: colorScheme))
//        .onAppear {
//            let appearance = UITabBarAppearance()
//            appearance.configureWithOpaqueBackground()
//            appearance.backgroundColor = UIColor(Color.TabbarBackground(for: colorScheme))
//
//            let itemAppearance = UITabBarItemAppearance()
//            itemAppearance.normal.iconColor = UIColor(Color.text(for: colorScheme).opacity(0.6))
//            itemAppearance.normal.titleTextAttributes = [
//                .foregroundColor: UIColor(Color.text(for: colorScheme).opacity(0.6)),
//            ]
//            itemAppearance.selected.iconColor = UIColor(Color.primary(for: colorScheme))
//            itemAppearance.selected.titleTextAttributes = [
//                .foregroundColor: UIColor(Color.primary(for: colorScheme)),
//            ]
//
//            appearance.stackedLayoutAppearance = itemAppearance
//            appearance.inlineLayoutAppearance = itemAppearance
//            appearance.compactInlineLayoutAppearance = itemAppearance
//
//            UITabBar.appearance().standardAppearance = appearance
//            if #available(iOS 15.0, *) {
//                UITabBar.appearance().scrollEdgeAppearance = appearance
//            }
//        }
//    }
//}
//
//struct HomeViewlib: View {
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var isShowingProfile = false
//    @State private var prefetchedUser: User? = nil
//    @State private var prefetchedLibrary: Library? = nil
//    @State private var isPrefetchingProfile = false
//    @State private var prefetchError: String? = nil
//    
//    var body: some View {
//        NavigationView {
//            ZStack{
//                ReusableBackground(colorScheme: colorScheme)
////                Text("Home Screen librarian")
////                    .navigationTitle("Home")
//                bookViewLibrarian()
//            }
//            .navigationBarLargeTitleItems(trailing: ProfileIcon(isShowingProfile: $isShowingProfile))
//            .task {
//                await prefetchProfileData()
//            }
//        }
//        .sheet(isPresented: $isShowingProfile) {
//            Group {
//                if isPrefetchingProfile {
//                    ProgressView("Loading Profile...")
//                        .padding()
//                } else if let user = prefetchedUser, let library = prefetchedLibrary {
//                    ProfileView(prefetchedUser: user, prefetchedLibrary: library)
//                        .navigationBarItems(trailing: Button("Done") {
//                            isShowingProfile = false
//                        })
//                } else {
//                    VStack(spacing: 16) {
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .font(.largeTitle)
//                            .foregroundColor(.orange)
//                        Text("Could Not Load Profile")
//                            .font(.headline)
//                        if let errorMsg = prefetchError {
//                            Text(errorMsg)
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                                .multilineTextAlignment(.center)
//                        }
//                        Button("Retry") {
//                            Task { await prefetchProfileData() }
//                        }
//                        .buttonStyle(.borderedProminent)
//                    }
//                    .padding()
//                }
//            }
//        }
//    }
//    private func prefetchProfileData() async {
//        // Avoid redundant fetches if already loading or data exists
//        guard !isPrefetchingProfile else { return }
//        
//        isPrefetchingProfile = true
//        prefetchError = nil
//        print("Prefetching profile data...") // Debug log
//
//        do {
//            // First try to get from cache
//            if let cachedUser = UserCacheManager.shared.getCachedUser() {
//                print("Using cached user data")
//                let libraryData = try await fetchLibraryData(libraryId: cachedUser.library_id)
//                
//                await MainActor.run {
//                    self.prefetchedUser = cachedUser
//                    self.prefetchedLibrary = libraryData
//                    self.isPrefetchingProfile = false
//                }
//                return
//            }
//            
//            // If no cache, fetch from server
//            guard let currentUser = try await LoginManager.shared.getCurrentUser() else {
//                throw NSError(domain: "HomeViewAdmin", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user session found."])
//            }
//
//            // Fetch library details
//            let libraryData = try await fetchLibraryData(libraryId: currentUser.library_id)
//
//            // Update state on the main thread
//            await MainActor.run {
//                self.prefetchedUser = currentUser
//                self.prefetchedLibrary = libraryData
//                self.isPrefetchingProfile = false
//                print("Profile data prefetched successfully.") // Debug log
//            }
//        } catch {
//            // Update state on the main thread
//            await MainActor.run {
//                self.prefetchError = error.localizedDescription
//                self.isPrefetchingProfile = false
//                self.prefetchedUser = nil
//                self.prefetchedLibrary = nil
//                print("Error prefetching profile data: \(error.localizedDescription)") // Debug log
//            }
//        }
//    }
//    
//    private func fetchLibraryData(libraryId: String) async throws -> Library {
//             guard let token = try? LoginManager.shared.getCurrentToken(), // Make sure LoginManager is accessible
//                   let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/libraries/\(libraryId)") else {
//                 throw URLError(.badURL)
//             }
//
//             var request = URLRequest(url: url)
//             request.httpMethod = "GET"
//             request.setValue("application/json", forHTTPHeaderField: "Accept")
//             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//             let (data, response) = try await URLSession.shared.data(for: request)
//
//             guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                  // Improved error handling based on status code
//                  let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
//                  throw NSError(domain: "APIError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)"])
//             }
//             
//             do {
//                 return try JSONDecoder().decode(Library.self, from: data)
//             } catch {
//                print("JSON Decoding Error for Library: \(error)")
//                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
//                throw error // Re-throw the decoding error
//             }
//         }
//}
//
//struct UsersViewlib: View {
//    var body: some View {
//        NavigationView {
//            Text("Users Screen librarian")
//                .navigationTitle("Users")
//        }
//    }
//}
//
//struct ManageViewlib: View {
//    var body: some View {
//        NavigationView {
//            Text("Manage Screen librarian")
//                .navigationTitle("Manage")
//        }
//    }
//}
//
//#Preview {
//    LibrarianTabbar()
//}

import SwiftUI

struct LibrarianTabbar: View {
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
            } else {
                TabView(selection: $selectedTab) {
                    // ...existing code...
                    HomeViewLibrarian()
                        .tag(0)
                        .tabItem {
                            Image(systemName: "house")
                                .accessibilityHidden(true)
                            Text("Home")
                                .accessibilityLabel("Home Tab")
                        }
                    
                    RequestViewLibrarian()
                        .tag(1)
                        .tabItem {
                            Image(systemName: "arrow.right.arrow.left")
                                .accessibilityHidden(true)
                            Text("Requests")
                                .accessibilityLabel("Requests Tab")
                        }
                    
                    UsersViewLibrarian()
                        .tag(2)
                        .tabItem {
                            Image(systemName: "person.3")
                                .accessibilityHidden(true)
                            Text("Users")
                                .accessibilityLabel("Users Tab")
                        }
                }
                .accentColor(Color.primary(for: colorScheme))
                .toolbarBackground(Color.TabbarBackground(for: colorScheme), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(colorScheme, for: .tabBar)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))) { _ in
                    print("Received logout notification in LibrarianTabbar")
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

struct LibrarianTabbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LibrarianTabbar()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            LibrarianTabbar()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
