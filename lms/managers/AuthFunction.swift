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

}
class LoginManager {
    static let shared = LoginManager()

    private init() {}

    func login(email: String, password: String) async throws -> (User, UserRole) {
        

        do {
            // Sign in with Supabase
            let response = try await supabase.auth.signIn(email: email, password: password)

            // Save JWT Token in Keychain
            let accessToken = response.accessToken
            try KeychainManager.shared.saveToken(accessToken)

            // Get the token back from Keychain

            // Build the secure API request
            print(response.user.id)
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users/\(response.user.id)") else {
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
            let user = User(
                id: response.user.id,
                email: response.user.email!,
                role: decodedResponse.role,
                name: decodedResponse.name,
                library_id: decodedResponse.library_id
            )

            return (user, decodedResponse.role)
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
        // Delete the token from Keychain
        try KeychainManager.shared.deleteToken()
        // Sign out from Supabase
        try await supabase.auth.signOut()
    }

    func getCurrentUser() async throws -> User? {
        do {
            let accessToken = try getCurrentToken()
            let user = try await supabase.auth.user()
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users/\(user.id)") else {
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
            return User(
                id: user.id,
                email: user.email!,
                role: decodedResponse.role,
                name: decodedResponse.name,
                library_id: decodedResponse.library_id
            )
        } catch {
            print("Error getting current user: \(error)")
            return nil
        }
    }

    // Helper function to get the current JWT token
    func getCurrentToken() throws -> String {
        return try KeychainManager.shared.getToken()
    }
}
