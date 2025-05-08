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
    case userInactive
}

struct APIUserResponse: Codable {

    let role: UserRole
    let name: String
    let library_id : String
    let age: Int?
    let phone_number: String?
    let gender: String?
    let is_active: Bool
    let interests: [String]?
    let wishlist_book_ids:[UUID]
    let borrowed_book_ids:[UUID]
    let reserved_book_ids:[UUID]

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
                guard let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/users/\(response.user.id)") else {
                    print("Invalid URL constructed")
                    throw LoginError.unknownError
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 30 // Increase timeout

                print("Making API request to fetch user data")
                let (data, httpResponse) = try await URLSession.shared.data(for: request)

                guard let httpResponse = httpResponse as? HTTPURLResponse else {
                    print("Invalid HTTP response")
                    throw LoginError.unknownError
                }

                print("API Response Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }

                // Handle different HTTP status codes
                switch httpResponse.statusCode {
                case 200:
                    // Success, continue with processing
                    break
                case 401:
                    // Unauthorized - token error
                    try KeychainManager.shared.deleteToken()
                    throw LoginError.tokenError
                case 404:
                    // User not found
                    throw LoginError.roleNotFound
                case 500...599:
                    // Server error
                    throw LoginError.unknownError
                default:
                    throw LoginError.unknownError
                }

                // Decode the JSON into your APIUserResponse model
                let decodedResponse = try JSONUtility.shared.decode(APIUserResponse.self, from: data)
                print("User data decoded successfully")
                
                // Check if user is active
                if !decodedResponse.is_active {
                    // Clear the token since we won't allow login
                    try KeychainManager.shared.deleteToken()
                    print("User is inactive")
                    throw LoginError.userInactive
                }
                
                let libraryID = decodedResponse.library_id
                try KeychainManager.shared.saveLibraryId(libraryID)

                // Construct User object
                let user = User(
                    id: response.user.id,
                    email: response.user.email!,
                    role: decodedResponse.role,
                    name: decodedResponse.name,
                    is_active: decodedResponse.is_active,
                    library_id: decodedResponse.library_id,
                    borrowed_book_ids: decodedResponse.borrowed_book_ids,
                    reserved_book_ids: decodedResponse.reserved_book_ids,
                    wishlist_book_ids:decodedResponse.wishlist_book_ids,
                    age: decodedResponse.age,
                    phone_number: decodedResponse.phone_number,
                    interests: decodedResponse.interests,
                    gender: decodedResponse.gender
                )

                // Cache the user data
                UserCacheManager.shared.cacheUser(user)
                
                // Prefetch library data
                let libraryData = try await fetchLibraryData(libraryId: libraryID)
                print("Library data prefetched successfully")

                return (user, decodedResponse.role)
            } catch let error as LoginError {
                throw error
            } catch let error as URLError where error.code == .networkConnectionLost {
                print("Network connection lost, retrying... (attempt \(currentRetry + 1)/\(maxRetries))")
                currentRetry += 1
                if currentRetry == maxRetries {
                    print("Max retries reached, throwing network error")
                    throw LoginError.networkError
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            } catch let error as PostgrestError {
                print("Postgrest Error: \(error)")
                if error.code == "42P17" {
                    throw LoginError.roleNotFound
                }
                throw LoginError.invalidCredentials
            } catch let error as AuthError {
                print("Auth Error: \(error)")
                throw LoginError.invalidCredentials
            } catch {
                print("Unexpected Error: \(error)")
                throw LoginError.unknownError
            }
        }
        throw LoginError.networkError
    }

    func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? getCurrentToken(),
              let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/libraries/\(libraryId)") else {
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
                    
                    // Check specifically for user_already_exists error
                    if error.errorCode.rawValue == "user_already_exists" {
                        completion(.failure(LoginError.signupError("User already registered")))
                    } else {
                        completion(.failure(LoginError.signupError("Authentication error during signup: \(error.localizedDescription)")))
                    }
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
        try? KeychainManager.shared.deleteToken()
        try? KeychainManager.shared.deleteLibraryId()
        UserCacheManager.shared.clearCache()
        AnalyticsHandler.shared.clearCache()
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "lastViewedBooks")
        defaults.removeObject(forKey: "userPreferences")
        
        
        try await supabase.auth.signOut()
    }

    func FetchUser()async -> User?{
        do {
            // If not in cache, try to get token from keychain
            let accessToken = try KeychainManager.shared.getToken()
            let supabaseUser = try await supabase.auth.user()
            
            guard let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/users/\(supabaseUser.id)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Decode the JSON into your APIUserResponse model
            let decodedResponse = try JSONUtility.shared.decode(APIUserResponse.self, from: data)
            print(decodedResponse)
            
            // Construct User object
            let appUser = User(
                id: supabaseUser.id,
                email: supabaseUser.email!,
                role: decodedResponse.role,
                name: decodedResponse.name,
                is_active: decodedResponse.is_active,
                library_id: decodedResponse.library_id,
                borrowed_book_ids: decodedResponse.borrowed_book_ids,
                reserved_book_ids: decodedResponse.reserved_book_ids,
                wishlist_book_ids:decodedResponse.wishlist_book_ids,
                age: decodedResponse.age,
                phone_number: decodedResponse.phone_number,
                interests: decodedResponse.interests,
                gender: decodedResponse.gender
            )
            
            // Cache the user data
            UserCacheManager.shared.cacheUser(appUser)
            
            return appUser
        } catch {
            print("Error getting current user:")
            error.logDetails()
            return nil
        }
    }
    
    func getCurrentUser() async throws -> User? {
        let otpVerified = UserCacheManager.shared.getCachedOtp() != nil
        if !otpVerified {
            return nil
        }
        // First try to get from cache
        if let cachedUser = UserCacheManager.shared.getCachedUser() {
            print("Returning cached user data")
            return cachedUser
        }
        
        return await FetchUser()
    }
    
    func checkSession() async -> Bool {
        do {
            // First check if we have a valid cached user
            if UserCacheManager.shared.isUserCached() {
                print("Valid user found in cache")
                return true
            }
            
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
            print("Session check error:")
            error.logDetails()
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

    func generateOTP(email: String) async throws -> Bool {
        print("🔑 Starting OTP generation for email: \(email)")
        guard let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/otp/generate") else {
            print("❌ Invalid URL")
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = ["email": email]
        print("📤 Request payload: \(payload)")
        
        let jsonData = try JSONUtility.shared.encodeFromDictionary(payload)
        request.httpBody = jsonData

        print("🌐 Making API request to: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response status code: \(httpResponse.statusCode)")
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response data: \(responseString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            print("❌ Invalid response status code")
            throw LoginError.unknownError
        }

        struct OTPResponse: Codable {
            let success: Bool
            let message: String
        }

        let otpResponse = try JSONUtility.shared.decode(OTPResponse.self, from: data)
        print("✅ OTP generation response: \(otpResponse)")
        return otpResponse.success
    }

    func verifyOTP(email: String, otp: String) async throws -> Bool {
        guard let url = URL(string: "https://www.anwinsharon.com/lms/api/v1/otp/verify") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = ["email": email, "otp": otp]
        let jsonData = try JSONUtility.shared.encodeFromDictionary(payload)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw LoginError.unknownError
        }

        struct OTPResponse: Codable {
            let success: Bool
            let message: String
        }

        let otpResponse = try JSONUtility.shared.decode(OTPResponse.self, from: data)
        //store otp verification in device
        UserCacheManager.shared.cacheOtp()
        return otpResponse.success
    }
    func addToWishlist(bookId:UUID){
        if var cachedUser = UserCacheManager.shared.getCachedUser(){
            cachedUser.wishlist_book_ids.append(bookId)
            UserCacheManager.shared.updateUser(cachedUser)
        }
    }
    func removeFromWishlist(bookId:UUID){
        if var cachedUser = UserCacheManager.shared.getCachedUser(){
            if let index = cachedUser.wishlist_book_ids.firstIndex(of: bookId){
                cachedUser.wishlist_book_ids.remove(at: index)
            }
            UserCacheManager.shared.updateUser(cachedUser)
        }
    }
}
