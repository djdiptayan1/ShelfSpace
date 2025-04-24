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
