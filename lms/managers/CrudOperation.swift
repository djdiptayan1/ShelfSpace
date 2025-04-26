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

            // Fix: Don't access wrappedValue, just encode the AnyEncodable objects directly
            let jsonData = try JSONEncoder().encode(userData)
            request.httpBody = jsonData

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
            print("Error saving user data via API: \(error)")
            DispatchQueue.main.async {
                completion(false)
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

            // Make the network request
            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug print the response data
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

            // Create a decoder without automatic key conversion since we're handling it in our model
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse.self, from: data)

            DispatchQueue.main.async {
                completion(.success(apiResponse.data))
            }
        } catch {
            print("Error fetching libraries: \(error)")
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
            // Sign up the user with Supabase Auth - only email and password
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

            // Fix: Don't access wrappedValue, just encode the AnyEncodable objects directly
            let jsonData = try JSONEncoder().encode(userData)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug print the response data
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
            // Handle Auth errors specifically
            DispatchQueue.main.async {
                print("Auth Signup Error: \(error)")
                completion(.failure(LoginError.signupError("Authentication error during signup: \(error.localizedDescription)")))
            }
        } catch {
            // Handle any other errors
            DispatchQueue.main.async {
                print("Generic Signup Error: \(error)")
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

            // Define the full response structure
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

            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase // in case you prefer camelCase models
            let apiResponse = try decoder.decode(APIResponse.self, from: data)

            let genres = apiResponse.data.map { $0.name }

            DispatchQueue.main.async {
                completion(.success(genres))
            }
        } catch {
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

    guard let token = try? KeychainManager.shared.getToken() else {
        throw URLError(.userAuthenticationRequired)
    }

    let libraryIdString: String
    do {
        libraryIdString = try KeychainManager.shared.getLibraryId()
        print("Using library ID from keychain: \(libraryIdString)")
    } catch {
        print("Error getting library ID from keychain: \(error)")
        throw error
    }

    guard let libraryId = UUID(uuidString: libraryIdString),
          let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    // Use a consistent ISO8601 format for sending.
    // The default ISO8601Format() might not include fractional seconds, which is fine for sending.
    let publishedDateString = book.publishedDate?.ISO8601Format() ?? Date().ISO8601Format()

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

    let jsonData = try JSONEncoder().encode(payload)
    request.httpBody = jsonData

    print("📤 Creating book with data: \(String(data: jsonData, encoding: .utf8) ?? "")")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    print("📥 Server response status code: \(httpResponse.statusCode)")

    if let responseString = String(data: data, encoding: .utf8) {
        print("📥 Server response body: \(responseString)")
    }

    if httpResponse.statusCode == 201 {
        // --- FIX: Use .custom Date Decoding Strategy ---
        let decoder = JSONDecoder()

        // Configure the formatter that understands fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Assign the custom decoding logic
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try parsing with fractional seconds
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            // Fallback: Try parsing without fractional seconds if the first attempt failed
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]
            if let date = fallbackFormatter.date(from: dateString) {
                print("⚠️ Warning: Parsed date '\(dateString)' without expected fractional seconds.")
                return date
            }

            // If both formats fail, throw an errorss
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode date string '\(dateString)' as ISO8601")
        }
        // --- End FIX ---

        do {
            let createdBook = try decoder.decode(BookModel.self, from: data)
            print("✅ Book created successfully with ID: \(createdBook.id)")
            return createdBook
        } catch {
            print("❌ Error decoding successful response: \(error)")
            // Add more detailed decoding error info if helpful
            if let decodingError = error as? DecodingError {
                print("Decoding Error Details: \(decodingError)")
            }
            throw error // Re-throw the specific decoding error
        }
    } else {
        // Error handling remains the same
        do {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            print("❌ Error creating book: \(errorResponse.errorMessage)")
            throw NSError(domain: "BookCreationError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
        } catch {
            let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error creating book (raw): \(rawErrorMessage)")
            print("Underlying decoding error (if any): \(error)")
            throw NSError(domain: "BookCreationError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
        }
    }
}

func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) { // FULLY WORKING
    Task {
        do {
            // Get authentication token from KeychainManager
            guard let token = try? KeychainManager.shared.getToken() else {
                throw BookFetchError.tokenMissing
            }

            // Get library ID from KeychainManager
            let libraryIdString: String
            do {
                libraryIdString = try KeychainManager.shared.getLibraryId()
                print("Using library ID from keychain: \(libraryIdString)")
            } catch {
                print("Error getting library ID from keychain: \(error)")
                throw BookFetchError.libraryIdMissing
            }

            // Create URL
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books") else {
                throw BookFetchError.invalidURL
            }

            // Create URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "accept")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Make the network request
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check if the response is valid
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BookFetchError.unknown
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw BookFetchError.serverError(httpResponse.statusCode)
            }

            // Parse the JSON response
            let decoder = JSONDecoder()
            // Replace the current date decoding strategy with a custom one
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                if let date = dateFormatter.date(from: dateString) {
                    return date
                }

                // Fallback to ISO8601
                let backupFormatter = ISO8601DateFormatter()
                if let date = backupFormatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }

            do {
                let booksResponse = try decoder.decode(BooksResponse.self, from: data)

                // Process the books to ensure they have appropriate default values
                var processedBooks = booksResponse.data

                // Process each book to ensure authorNames is initialized
                processedBooks = processedBooks.map { book in
                    var mutableBook = book
                    if mutableBook.authorNames == nil {
                        mutableBook.authorNames = []
                    }
                    return mutableBook
                }

                // Return the processed books via completion handler
                DispatchQueue.main.async {
                    completion(.success(processedBooks))
                    print("Successfully fetched \(processedBooks.count) books")
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(BookFetchError.decodingError(error)))
                }
            }
        } catch let error as BookFetchError {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        } catch {
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

            // Encode the policy object directly
            let jsonData = try JSONEncoder().encode(policyData)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug print the response data
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

            // Parse the response to get the policy_id
            if let responsePolicy = try? JSONDecoder().decode(Policy.self, from: data) {
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
            print("Error saving policy data via API: \(error)")
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

            // Create a copy of the policy with the specified ID
            var updatedPolicy = policyData
            updatedPolicy.policy_id = policyId

            let jsonData = try JSONEncoder().encode(updatedPolicy)
            request.httpBody = jsonData

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

            print("Policy updated successfully")
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            print("Error updating policy data via API: \(error)")
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

            // Debug print the response data
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

            // Decode the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Check if response is an array or single object
            if let policy = try? decoder.decode(Policy.self, from: data) {
                DispatchQueue.main.async {
                    completion(policy)
                }
            } else if let policies = try? decoder.decode([Policy].self, from: data), let firstPolicy = policies.first {
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
            print("Error fetching policy data via API: \(error)")
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
