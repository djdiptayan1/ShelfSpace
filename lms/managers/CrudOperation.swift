//
//  CrudOperation.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//
import Foundation
import Supabase
import SwiftUI

func insertUser(userData: [String: AnyEncodable], completion: @escaping (Bool) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("Sending user data to API with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Ensure gender is included and properly formatted
            var updatedUserData = userData
            if let gender = userData["gender"]?.wrappedValue as? String {
                updatedUserData["gender"] = AnyEncodable(gender.lowercased())
                print("Gender value being sent: \(gender.lowercased())")
            }

            // Use JSONUtility for encoding
            let jsonData = try JSONUtility.shared.encodeFromDictionary(updatedUserData)
            request.httpBody = jsonData

            // Debug print the request data
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("API Request Data: \(jsonString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug print the response data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            print("User inserted successfully")
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            print("Error saving user data via API:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}

func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            let libraryId = try KeychainManager.shared.getLibraryId()

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users?libraryId=\(libraryId)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            // Decode the wrapper response first
            let responseWrapper = try JSONUtility.shared.decode(PaginatedResponse<[User]>.self, from: data)
            
            // Now we can access the users array
            let users = responseWrapper.data
            
            DispatchQueue.main.async {
                completion(.success(users))
            }
        } catch {
            print("Error fetching users:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}

func fetchLibraries(completion: @escaping (Result<[Library], Error>) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("fetching libraries with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }

            // Define the full response structure
            struct APIResponse: Codable {
                let data: [Library]
                let pagination: Pagination
            }

            struct Pagination: Codable {
                let totalItems: Int
                let currentPage: Int
                let itemsPerPage: Int
                let totalPages: Int
            }

            // Use JSONUtility for decoding
            let apiResponse = try JSONUtility.shared.decode(APIResponse.self, from: data)

            DispatchQueue.main.async {
                completion(.success(apiResponse.data))
            }
        } catch {
            print("Error fetching libraries:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}

func addLibrians(email: String,
                 password: String,
                 name: String,
                 userData: [String: AnyEncodable], completion: @escaping (Result<Bool, Error>) -> Void) {
    Task {
        do {
            print("adding librarian backend starting")
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            let token = try KeychainManager.shared.getToken()

            print("Access Token while adding librian: \(token)")
            let userId = authResponse.user.id

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Use JSONUtility for encoding
            let jsonData = try JSONUtility.shared.encodeFromDictionary(userData)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            print("User inserted successfully")
            DispatchQueue.main.async {
                completion(.success(true))
            }
        } catch let error as AuthError {
            DispatchQueue.main.async {
                print("Auth Signup Error:")
                error.logDetails()
                completion(.failure(LoginError.signupError("Authentication error during signup: \(error.localizedDescription)")))
            }
        } catch {
            DispatchQueue.main.async {
                print("Generic Signup Error:")
                error.logDetails()
                completion(.failure(error))
            }
        }
    }
}

func fetchGenres(completion: @escaping (Result<[String], Error>) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("fetching genres with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/genres") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }

            struct APIResponse: Codable {
                let data: [Genre]
                let pagination: Pagination
            }

            struct Genre: Codable {
                let genre_id: String
                let name: String
            }

            struct Pagination: Codable {
                let totalItems: Int
                let currentPage: Int
                let itemsPerPage: Int
                let totalPages: Int
            }

            // Use JSONUtility for decoding
            let apiResponse = try JSONUtility.shared.decode(APIResponse.self, from: data)
            let genres = apiResponse.data.map { $0.name }

            DispatchQueue.main.async {
                completion(.success(genres))
            }
        } catch {
            print("Error fetching genres:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}

func fetchAuthors(completion: @escaping (Result<[String], Error>) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("fetching libraries with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/authors") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let response = try await supabase
                .from("authors")
                .select("name")
                .execute()

            let data = response.data
            let decoder = JSONDecoder()
        }
    }
}

func createBook(book: BookModel) async throws -> BookModel { // FULLY WORKING
    print("Add BOOK API CALL HERE ...")
        
        struct CreateBookRequest: Encodable {
            let library_id: UUID
            let title: String
            let isbn: String
            let description: String
            let total_copies: Int
            let available_copies: Int
            let reserved_copies: Int
            let published_date: String
            let author_ids: [UUID]?
            let genre_ids: [UUID]?
        }
        
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
            
            var errorMessage: String {
                return message ?? error ?? "Unknown error occurred"
            }
        }
        
        // Get auth token and library ID
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let libraryIdString = try KeychainManager.shared.getLibraryId()
        guard let libraryId = UUID(uuidString: libraryIdString),
              let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books") else {
            throw URLError(.badURL)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Format date consistently
        let publishedDateString = book.publishedDate?.ISO8601Format() ?? Date().ISO8601Format()
        
        // Prepare payload
        let payload = CreateBookRequest(
            library_id: libraryId,
            title: book.title,
            isbn: book.isbn ?? "",
            description: book.description ?? "",
            total_copies: book.totalCopies,
            available_copies: book.availableCopies,
            reserved_copies: book.reservedCopies,
            published_date: publishedDateString,
            author_ids: book.authorIds.isEmpty ? nil : book.authorIds,
            genre_ids: book.genreIds.isEmpty ? nil : book.genreIds
        )
        
        // Encode request using the utility
        let jsonData = try JSONUtility.shared.encode(payload)
        request.httpBody = jsonData
        
        print("📤 Creating book with data: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📥 Server response status code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Server response body: \(responseString)")
        }
        
        // Handle successful response
        if httpResponse.statusCode == 201 {
            // Use the JSON utility to decode the response
            do {
                let createdBook = try JSONUtility.shared.decode(BookModel.self, from: data)
                print("✅ Book created successfully with ID: \(createdBook.id)")
                return createdBook
            } catch {
                print("❌ Error decoding successful response:")
                error.logDetails()
                throw error
            }
        } else {
            // Handle error response
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error creating book: \(errorResponse.errorMessage)")
                throw NSError(domain: "BookCreationError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error creating book (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "BookCreationError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }
}

func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) { // FULLY WORKING
    Task {
            do {
                // Get authentication token and library ID
                guard let token = try? KeychainManager.shared.getToken() else {
                    throw BookFetchError.tokenMissing
                }
                
                let libraryIdString = try KeychainManager.shared.getLibraryId()
                print("Using library ID from keychain: \(libraryIdString)")
                
                // Create URL request
                guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books") else {
                    throw BookFetchError.invalidURL
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "accept")
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                // Make the network request
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check response status
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw BookFetchError.unknown
                }
                
                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    throw BookFetchError.serverError(httpResponse.statusCode)
                }
                
                // Use the JSON utility to decode the response
                let booksResponse = try JSONUtility.shared.decode(BooksResponse.self, from: data)
                
                // Process books if needed
                var processedBooks = booksResponse.data.map { book in
                    var mutableBook = book
                    if mutableBook.authorNames == nil {
                        mutableBook.authorNames = []
                    }
                    return mutableBook
                }
                
                // Return results via completion handler
                DispatchQueue.main.async {
                    completion(.success(processedBooks))
                    print("Successfully fetched \(processedBooks.count) books")
                }
            } catch let error as BookFetchError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                // Log detailed error information
                error.logDetails()
                
                DispatchQueue.main.async {
                    completion(.failure(BookFetchError.networkError(error)))
                }
            }
        }
}

func insertPolicy(policyData: Policy, completion: @escaping (Bool, UUID?) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("Sending policy data to API with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/policies") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Use JSONUtility for encoding
            let jsonData = try JSONUtility.shared.encode(policyData)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            // Use JSONUtility for decoding
            if let responsePolicy = try? JSONUtility.shared.decode(Policy.self, from: data) {
                print("Policy inserted successfully with ID: \(responsePolicy.policy_id?.uuidString ?? "unknown")")
                DispatchQueue.main.async {
                    completion(true, responsePolicy.policy_id)
                }
            } else {
                print("Policy inserted but could not parse response")
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            }
        } catch {
            print("Error saving policy data via API:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(false, nil)
            }
        }
    }
}

func updatePolicy(policyId: UUID, policyData: Policy, completion: @escaping (Bool) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("Updating policy data for ID: \(policyId)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/policies/\(policyId.uuidString)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            var updatedPolicy = policyData
            updatedPolicy.policy_id = policyId

            // Use JSONUtility for encoding
            let jsonData = try JSONUtility.shared.encode(updatedPolicy)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            print("Policy updated successfully")
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            print("Error updating policy data via API:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}

func fetchPolicy(libraryId: UUID, completion: @escaping (Policy?) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("Fetching policy data for library ID: \(libraryId)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/policies/library/\(libraryId.uuidString)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Use JSONUtility for decoding
            if let policy = try? JSONUtility.shared.decode(Policy.self, from: data) {
                DispatchQueue.main.async {
                    completion(policy)
                }
            } else if let policies = try? JSONUtility.shared.decode([Policy].self, from: data), let firstPolicy = policies.first {
                DispatchQueue.main.async {
                    completion(firstPolicy)
                }
            } else {
                print("Could not parse policy data")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } catch {
            print("Error fetching policy data via API:")
            error.logDetails()
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

private func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
}

func createUserWithAuth(email: String, password: String, name: String, role: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    Task {
        do {
            // First create auth account
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            let userId = authResponse.user.id
            let token = try KeychainManager.shared.getToken()
            let libraryIdString = try KeychainManager.shared.getLibraryId()

            // Prepare user data with proper types
            let userData: [String: Any] = [
                "user_id": userId.uuidString,
                "library_id": libraryIdString,
                "name": name,
                "email": email,
                "role": role,
                "is_active": true
            ]

            // Insert user data into database
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Use JSONUtility to encode the dictionary
            let jsonData = try JSONUtility.shared.encodeFromDictionary(userData)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorMsg)")
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            print("User created successfully")
            DispatchQueue.main.async {
                completion(.success(true))
            }
        } catch let error as AuthError {
            DispatchQueue.main.async {
                print("Auth Signup Error:")
                error.logDetails()
                completion(.failure(LoginError.signupError("Authentication error during signup: \(error.localizedDescription)")))
            }
        } catch {
            DispatchQueue.main.async {
                print("Generic Signup Error:")
                error.logDetails()
                completion(.failure(error))
            }
        }
    }
}
