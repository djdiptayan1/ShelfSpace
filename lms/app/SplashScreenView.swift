//
//  SplashScreenView.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
import SwiftUI
import DotLottie
// Create a global AppState to manage authentication state
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUserRole: UserRole?
    @Published var currentUser: User?
    @Published var currentLibrary: Library?
    @Published var prefetchError: String?
    @Published var shouldShowLogin: Bool = false
    
    func resetState() {
        isLoggedIn = false
        currentUserRole = nil
        currentUser = nil
        currentLibrary = nil
        shouldShowLogin = true
    }
}

struct SplashScreenView: View {
    @StateObject private var appState = AppState()
    @State private var animationDone = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if appState.isLoading {
                // Show splash screen
                ZStack {
                    ReusableBackground(colorScheme: colorScheme)
                    
                    VStack {
                        DotLottieAnimation(
                            fileName: "shelfspace",
                            config: AnimationConfig(
                                autoplay: true,
                                loop: true,
                                mode: .bounce,
                                speed: 0.5
                            )
                        )
                        .view()
                        .frame(width: 400, height: 400)
                        
//                        if let error = appState.prefetchError {
//                            Text(error)
//                                .foregroundColor(.red)
//                                .font(.caption)
//                                .padding(.top)
//                        }
                    }
                }
                .onAppear {
                    checkLoginStatus()
                }
            } else if appState.shouldShowLogin {
                // Show login screen when shouldShowLogin is true
                LoginView()
                    .environmentObject(appState)
            } else if appState.isLoggedIn {
                // Show appropriate screen based on user role
                switch appState.currentUserRole {
                case .admin:
                    AdminTabbar()
                        .environmentObject(appState)
                case .librarian:
                    LibrarianTabbar()
                        .environmentObject(appState)
                case .member:
                    UserTabbar()
                        .environmentObject(appState)
                case .none:
                    LoginView()
                        .environmentObject(appState)
                }
            } else {
                // Default to login screen
                LoginView()
                    .environmentObject(appState)
            }
        }
    }
    
    private func checkLoginStatus() {
        // Minimum display time for splash
        let minSplashTime = 1.0 // seconds
        let startTime = Date()
        
        Task {
            // Check if user session is valid
            let isSessionValid = await LoginManager.shared.checkSession()
            
            if isSessionValid {
                do {
                    // Get current user and role
                    if let user = try await LoginManager.shared.getCurrentUser() {
                        // Cache the user data immediately
                        UserCacheManager.shared.cacheUser(user)
                        
                        // Prefetch library data
                        let libraryData = try await LoginManager.shared.fetchLibraryData(libraryId: user.library_id)
                        
                        await MainActor.run {
                            appState.currentUser = user
                            appState.currentUserRole = user.role
                            appState.currentLibrary = libraryData
                            appState.isLoggedIn = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        appState.prefetchError = "Failed to load data: \(error.localizedDescription)"
                    }
                }
            }
            
            // Calculate time elapsed
            let elapsed = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minSplashTime - elapsed)
            
            // Ensure minimum splash time
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            // Update UI on main thread
            await MainActor.run {
                appState.isLoading = false
            }
        }
    }
    
    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
              let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "APIError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)"])
        }
        
        return try JSONDecoder().decode(Library.self, from: data)
    }
}
