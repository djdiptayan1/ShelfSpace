//
//  loginFunction.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//

import Foundation
import Supabase

enum LoginError: Error {
    case invalidCredentials
    case networkError
    case unknownError
    case roleNotFound
    case tokenError
    case signupError(String)
}

struct APIUserResponse: Codable {

    let role: UserRole
    let name: String
    let library_id : String
    let is_active: Bool

}
class LoginManager {
    static let shared = LoginManager()

    private init() {}

    func login(email: String, password: String) async throws -> (User, UserRole) {
        let maxRetries = 3
        var currentRetry = 0
        
        while currentRetry < maxRetries {
            do {
                print("Attempting login (attempt \(currentRetry + 1)/\(maxRetries))")
                
                // Sign in with Supabase
                let response = try await supabase.auth.signIn(email: email, password: password)
                print("Supabase auth successful")

                // Save JWT Token in Keychain
                let accessToken = response.accessToken
                try KeychainManager.shared.saveToken(accessToken)
                print("Token saved to keychain")

                // Get the token back from Keychain
                print("User ID: \(response.user.id)")
                guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users/\(response.user.id)") else {
                    print("Invalid URL constructed")
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 30 // Increase timeout

                print("Making API request to fetch user data")
                let (data, httpResponse) = try await URLSession.shared.data(for: request)

                if let httpResponseObject = httpResponse as? HTTPURLResponse {
                    print("API Response Status: \(httpResponseObject.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("API Response: \(responseString)")
                    }
                }

                // Decode the JSON into your APIUserResponse model
                let decodedResponse = try JSONDecoder().decode(APIUserResponse.self, from: data)
                print("User data decoded successfully")
                
                let libraryID = decodedResponse.library_id
                try! KeychainManager.shared.saveLibraryId(libraryID)

                // Construct User object
                let user = User(
                    id: response.user.id,
                    email: response.user.email!,
                    role: decodedResponse.role,
                    name: decodedResponse.name,
                    is_active: decodedResponse.is_active,
                    library_id: decodedResponse.library_id
                )

                // Cache the user data
                UserCacheManager.shared.cacheUser(user)
                
                // Prefetch library data
                let libraryData = try await fetchLibraryData(libraryId: libraryID)
                print("Library data prefetched successfully")

                return (user, decodedResponse.role)
            } catch let error as URLError where error.code == .networkConnectionLost {
                print("Network connection lost, retrying... (attempt \(currentRetry + 1)/\(maxRetries))")
                currentRetry += 1
                if currentRetry == maxRetries {
                    print("Max retries reached, throwing network error")
                    throw LoginError.networkError
                }
                // Wait for 1 second before retrying
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            } catch let error as DecodingError {
                print("Decoding error: \(error)")
                throw LoginError.unknownError
            } catch {
                print("Login error: \(error)")
                if let postgrestError = error as? PostgrestError {
                    if postgrestError.code == "42P17" {
                        throw LoginError.roleNotFound
                    }
                }
                throw LoginError.invalidCredentials
            }
        }
        throw LoginError.networkError
    }

    func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? getCurrentToken(),
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

    func signUp(
        email: String,
        password: String,
        completion: @escaping (Result<UUID, Error>) -> Void
    ) {
        Task {
            do {
                // Sign up the user with Supabase Auth - only email and password
                let authResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                let session = try await supabase.auth.session
                let accessToken = session.accessToken

                try KeychainManager.shared.saveToken(accessToken)
                print("Access Token while signing up: \(accessToken)")
                // Get the user ID from the auth response
                let userId = authResponse.user.id

                // Return success with the user ID
                DispatchQueue.main.async {
                    completion(.success(userId))
                }

            } catch let error as AuthError {
                // Handle Auth errors specifically
                DispatchQueue.main.async {
                    print("Auth Signup Error: \(error)")
                    completion(.failure(LoginError.signupError("Authentication error during signup: \(error.localizedDescription)")))
                }
            } catch {
                // Handle any other errors
                DispatchQueue.main.async {
                    print("Generic Signup Error: \(error)")
                    completion(.failure(error)) // Pass the original error
                }
            }
        }
    }

    func signOut() async throws {
        // Clear the user cache
        UserCacheManager.shared.clearCache()
        // Delete the token from Keychain
        try KeychainManager.shared.deleteToken()
        // Sign out from Supabase
        try await supabase.auth.signOut()
    }

    func getCurrentUser() async throws -> User? {
        // First try to get from cache
        if let cachedUser = UserCacheManager.shared.getCachedUser() {
            print("Returning cached user data")
            return cachedUser
        }
        
        do {
            let accessToken = try getCurrentToken()
            let supabaseUser = try await supabase.auth.user()
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users/\(supabaseUser.id)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)

            // Decode the JSON into your APIUserResponse model
            let decodedResponse = try JSONDecoder().decode(APIUserResponse.self, from: data)

            // Construct User object
            let appUser = User(
                id: supabaseUser.id,
                email: supabaseUser.email!,
                role: decodedResponse.role,
                name: decodedResponse.name,
                is_active: decodedResponse.is_active,
                library_id: decodedResponse.library_id
            )
            
            // Cache the user data
            UserCacheManager.shared.cacheUser(appUser)
            
            return appUser
        } catch {
            print("Error getting current user: \(error)")
            return nil
        }
    }
    
    func checkSession() async -> Bool {
        do {
            // Try to get the token from keychain
            let token = try KeychainManager.shared.getToken()
            
            // Check if token exists in keychain
            guard !token.isEmpty else {
                print("No token found in keychain")
                return false
            }
            
            // Validate session with Supabase
            let session = try await supabase.auth.session
            
            // Check if session is valid (not expired)
            let currentTimestamp = Date().timeIntervalSince1970
            if session.expiresAt > currentTimestamp {
                // Session is valid - verify by fetching current user
                if let _ = try await getCurrentUser() {
                    print("Session is valid")
                    return true
                } else {
                    print("Failed to get user details")
                    return false
                }
            } else {
                print("Session has expired")
                try KeychainManager.shared.deleteToken()
                return false
            }
        } catch {
            print("Session check error: \(error)")
            return false
        }
    }
    
    func refreshSession() async -> Bool {
        do {
            // Attempt to refresh the session
            _ = try await supabase.auth.refreshSession()
            
            // Get the new token
            let session = try await supabase.auth.session
            let newToken = session.accessToken
            
            // Save the new token
            try KeychainManager.shared.saveToken(newToken)
            
            return true
        } catch {
            print("Failed to refresh session: \(error)")
            return false
        }
    }

    // Helper function to get the current JWT token
    func getCurrentToken() throws -> String {
        return try KeychainManager.shared.getToken()
    }
}
