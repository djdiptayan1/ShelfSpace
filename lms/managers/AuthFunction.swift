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

class LoginManager {
    static let shared = LoginManager()

    private init() {}

    func login(email: String, password: String) async throws -> (User, UserRole) {
        do {
            // Sign in with Supabase
            let response = try await supabase.auth.signIn(email: email, password: password)

            // Store the JWT token in Keychain
            let accessToken = response.accessToken
            print("Access Token: \(accessToken)")
            try KeychainManager.shared.saveToken(accessToken)

            // Get user's role from the database
            struct RoleResponse: Codable {
                let role: UserRole
            }

            let roleResponse: RoleResponse = try await supabase
                //                .from("user_roles")
                .from("users")
                .select("role")
                //                .eq("id", value: response.user.id)
                .eq("user_id", value: response.user.id)
                .single()
                .execute()
                .value

            // Get user's metadata - proper handling of optional JSON
            let metadata = response.user.userMetadata
            let name: String
            if let nameValue = metadata["name"],
               let nameString = nameValue.stringValue {
                name = nameString
            } else {
                name = email
            }

            // Create User object
            let user = User(
                id: response.user.id,
                email: email,
                role: roleResponse.role,
                name: name
            )

            return (user, roleResponse.role)
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
            let session = try await supabase.auth.session
            if session.user == nil { return nil }
            let sessionUser = session.user

            struct RoleResponse: Codable {
                let role: UserRole
            }

            let roleResponse: RoleResponse = try await supabase
//                .from("user_roles")
                .from("users")
                .select("role")
//                .eq("id", value: sessionUser.id)
                .eq("user_id", value: sessionUser.id)
                .single()
                .execute()
                .value

            let metadata = sessionUser.userMetadata
            let name: String
            if let nameValue = metadata["name"],
               let nameString = nameValue.stringValue {
                name = nameString
            } else {
                name = sessionUser.email ?? "Unknown User"
            }

            return User(
                id: sessionUser.id,
                email: sessionUser.email ?? "unknown@example.com",
                role: roleResponse.role,
                name: name
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
