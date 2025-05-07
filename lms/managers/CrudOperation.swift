//
//  CrudOperation.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//
import Foundation
import Supabase
import SwiftUI

struct ErrorResponse: Decodable {
    let success: Bool
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let message: String
    }
    
    var errorMessage: String {
        return error.message
    }
}

func insertUser(userData: [String: Any], completion: @escaping (Bool) -> Void) {
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            print("Creating user with token: \(token)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Ensure all UUIDs are converted to strings before serialization
            var processedUserData = userData
            if let userId = userData["user_id"] as? UUID {
                processedUserData["user_id"] = userId.uuidString
            }
            if let borrowedIds = userData["borrowed_book_ids"] as? [UUID] {
                processedUserData["borrowed_book_ids"] = borrowedIds.map { $0.uuidString }
            }
            if let reservedIds = userData["reserved_book_ids"] as? [UUID] {
                processedUserData["reserved_book_ids"] = reservedIds.map { $0.uuidString }
            }
            if let wishlistIds = userData["wishlist_book_ids"] as? [UUID] {
                processedUserData["wishlist_book_ids"] = wishlistIds.map { $0.uuidString }
            }

            // Convert the processed userData dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: processedUserData, options: [])
            request.httpBody = jsonData

            print("Sending user data: \(String(data: jsonData, encoding: .utf8) ?? "")")

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

            print("User created successfully")
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            print("Error creating user: \(error)")
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

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/users?limit=200&libraryId=\(libraryId)") else {
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

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries?limit=200") else {
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

struct AuthorListResponse: Decodable {
    let data: [AuthorModel]
}

func getOrCreateAuthorId(authorName: String, bookId: UUID) async throws -> UUID {
    let token = try KeychainManager.shared.getToken()
    // 1. Check if author exists
    guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/authors?search=\(authorName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? authorName)") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        let authorList = try JSONDecoder().decode(AuthorListResponse.self, from: data)
        if let existing = authorList.data.first(where: { $0.name.lowercased() == authorName.lowercased() }) {
            return existing.id
        }
    }
    // 2. If not found, create author
    guard let postUrl = URL(string: "https://lms-temp-be.vercel.app/api/v1/authors") else {
        throw URLError(.badURL)
    }
    var postRequest = URLRequest(url: postUrl)
    postRequest.httpMethod = "POST"
    postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    postRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    postRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let payload: [String: Any] = [
        "name": authorName,
        "bio": authorName,
        "book_ids": [bookId.uuidString]
    ]
    postRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
    let (postData, postResponse) = try await URLSession.shared.data(for: postRequest)
    guard let postHttpResponse = postResponse as? HTTPURLResponse, (200...299).contains(postHttpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }
    let createdAuthor = try JSONDecoder().decode(AuthorModel.self, from: postData)
    return createdAuthor.id
}

func createBook(book: BookModel) async throws -> BookModel {
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
        let author_ids: [String]?
        let genre_ids: [UUID]?
        let genre_names: [String]? // <- ADD this
        let cover_image_url: String? // <- ADD this
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
    let cleanCoverUrl = book.coverImageUrl?.replacingOccurrences(of: "\\/", with: "/")

    // Prepare payload with proper escaping
    let payload = CreateBookRequest(
        library_id: libraryId,
        title: book.title.replacingOccurrences(of: "'", with: ""), // Escape single quotes
        isbn: book.isbn ?? "",
        description: book.description?.replacingOccurrences(of: "'", with: "") ?? "", // Escape single quotes
        total_copies: book.totalCopies,
        available_copies: book.totalCopies,
        reserved_copies: 0,
        published_date: publishedDateString,
        author_ids: book.authorIds.map { $0.uuidString.lowercased() },
        genre_ids: book.genreIds.isEmpty ? nil : book.genreIds,
        genre_names: book.genreNames?.isEmpty == true ? nil : book.genreNames,
        cover_image_url: cleanCoverUrl
    )

    // Encode request using the utility
    let jsonData = try JSONUtility.shared.encode(payload)

    // Debug print the request data
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📤 Creating book with data: \(jsonString)")
    }

    request.httpBody = jsonData

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

class BookHandler:CacheHandler<[BookModel]>{
    static let shared = BookHandler(cacheFileName: "book_cache.json")
}

// Creating a class to manage book pagination state
class BookPaginationManager {
    static let shared = BookPaginationManager()
    
    var currentPage = 1
    var totalPages = 1
    var isLoading = false
    var itemsPerPage = 15
    var books: [BookModel] = []
    
    func hasMorePages() -> Bool {
        return currentPage < totalPages
    }
    
    func reset() {
        currentPage = 1
        totalPages = 1
        books = []
        isLoading = false
    }
}

// Updated function signature to include isLoadingMore parameter
func fetchBooks(page: Int? = nil, limit: Int = 15, sortBy: String = "title", sortOrder: String = "asc", isLoadingMore: Bool = false, completion: @escaping (Result<[BookModel], Error>) -> Void) {
    // Get pagination manager
    let paginationManager = BookPaginationManager.shared
    
    // If we're already loading or trying to load a page beyond total pages, return early
    if paginationManager.isLoading || (page != nil && page! > paginationManager.totalPages && paginationManager.totalPages > 0) {
        completion(.success(paginationManager.books))
        return
    }
    
    // Set current page - either use provided page or increment if loading more
    let currentPage: Int
    if let requestedPage = page {
        currentPage = requestedPage
    } else if isLoadingMore {
        currentPage = paginationManager.currentPage + 1
    } else {
        // Reset if this is a fresh load
        if !isLoadingMore {
            paginationManager.reset()
        }
        currentPage = 1
    }
    
    // Update state to loading
    paginationManager.isLoading = true
    
    Task {
        do {
            // Get authentication token and library ID
            guard let token = try? KeychainManager.shared.getToken() else {
                throw BookFetchError.tokenMissing
            }
            
            let libraryIdString = try KeychainManager.shared.getLibraryId()
            print("Using library ID from keychain: \(libraryIdString)")
            print("Fetching books, page \(currentPage) of \(paginationManager.totalPages)")
            
            // Create URL request with pagination parameters
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books?page=\(currentPage)&limit=\(limit)&sortBy=\(sortBy)&sortOrder=\(sortOrder)&libraryId=\(libraryIdString)") else {
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
            
            // Update pagination information
            paginationManager.currentPage = currentPage
            paginationManager.totalPages = booksResponse.pagination.totalPages
            
            // Process books
            var processedBooks = booksResponse.data.map { book in
                var mutableBook = book
                if mutableBook.authorNames == nil {
                    mutableBook.authorNames = []
                }
                return mutableBook
            }
            
            // Update books collection: append if loading more, otherwise replace
            if isLoadingMore {
                paginationManager.books.append(contentsOf: processedBooks)
            } else {
                paginationManager.books = processedBooks
            }
            
            // Cache the books
            BookHandler.shared.cacheData(paginationManager.books)
            
            // Return results via completion handler
            DispatchQueue.main.async {
                // Mark loading as complete
                paginationManager.isLoading = false
                
                // Return the complete collection (either just this page or all pages loaded so far)
                completion(.success(paginationManager.books))
                print("Successfully fetched \(processedBooks.count) books, page \(currentPage)/\(booksResponse.pagination.totalPages), total items: \(booksResponse.pagination.totalItems)")
            }
        } catch let error as BookFetchError {
            paginationManager.isLoading = false
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        } catch {
            // Log detailed error information
            error.logDetails()
            paginationManager.isLoading = false
            
            DispatchQueue.main.async {
                completion(.failure(BookFetchError.networkError(error)))
            }
        }
    }
}

// Helper function to load more books when user scrolls to bottom
func loadMoreBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) {
    let paginationManager = BookPaginationManager.shared
    
    // Check if there are more pages to load
    if paginationManager.hasMorePages() && !paginationManager.isLoading {
        // Call fetchBooks with isLoadingMore flag
        fetchBooks(isLoadingMore: true, completion: completion)
    } else {
        // Return the current set of books if there are no more to load
        completion(.success(paginationManager.books))
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
            let libraryID = try KeychainManager.shared.getLibraryId()
            let token = try KeychainManager.shared.getToken()
            print("Fetching policy data for library ID: \(libraryID)")

            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/policies/library/\(libraryID)") else {
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
            let token = try KeychainManager.shared.getToken()
            let libraryIdString = try KeychainManager.shared.getLibraryId()

            // Prepare user data with proper types
            let userData: [String: Any] = [
                "user_id": UUID().uuidString,
                "library_id": libraryIdString,
                "name": name,
                "email": email,
                "role": role,
                "is_active": true,
                "password":password
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

func updateBookAPI(book: BookModel) async throws -> BookModel {
    print("EDIT BOOK API CALL HERE ...")

    struct UpdateBookRequest: Encodable {
        let library_id: UUID
        let title: String
        let isbn: String
        let description: String
        let total_copies: Int
        let available_copies: Int
        let reserved_copies: Int
        let published_date: String
        let genre_names: [String]?
        let cover_image_url: String?
    }

    // Updated error response structure to match the actual API response

    // Get auth token and library ID
    guard let token = try? KeychainManager.shared.getToken() else {
        throw URLError(.userAuthenticationRequired)
    }

    let libraryIdString = try KeychainManager.shared.getLibraryId()
    guard let libraryId = UUID(uuidString: libraryIdString),
          let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books/\(book.id.uuidString)") else {
        throw URLError(.badURL)
    }

    // Create request
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    // Format date consistently
    let publishedDateString = book.publishedDate?.ISO8601Format() ?? Date().ISO8601Format()
    let cleanCoverUrl = book.coverImageUrl?.replacingOccurrences(of: "\\/", with: "/")

    // Prepare payload
    let payload = UpdateBookRequest(
        library_id: libraryId,
        title: book.title,
        isbn: book.isbn ?? "",
        description: book.description ?? "",
        total_copies: book.totalCopies,
        available_copies: book.availableCopies,
        reserved_copies: book.reservedCopies,
        published_date: publishedDateString,
        genre_names: book.genreNames?.isEmpty == true ? nil : book.genreNames,
        cover_image_url: cleanCoverUrl
    )

    let jsonData = try JSONUtility.shared.encode(payload)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("\u{1F4E4} Updating book with data: \(jsonString)")
    }
    request.httpBody = jsonData

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
    if let responseString = String(data: data, encoding: .utf8) {
        print("\u{1F4E5} Server response body: \(responseString)")
    }

    if (200...299).contains(httpResponse.statusCode) {
        do {
            let updatedBook = try JSONUtility.shared.decode(BookModel.self, from: data)
            print("✅ Book updated successfully with ID: \(updatedBook.id)")
            return updatedBook
        } catch {
            print("❌ Error decoding successful response:")
            error.logDetails()
            throw error
        }
    } else {
        do {
            let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
            print("❌ Error updating book: \(errorResponse.errorMessage)")
            throw NSError(domain: "BookUpdateError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
        } catch {
            let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error updating book (raw): \(rawErrorMessage)")
            print("Underlying decoding error (if any):")
            error.logDetails()
            throw NSError(domain: "BookUpdateError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
        }
    }
}

func deleteBookAPI(bookId: UUID) async throws {
    guard let token = try? KeychainManager.shared.getToken() else {
        throw URLError(.userAuthenticationRequired)
    }
    guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books/\(bookId.uuidString)") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("*/*", forHTTPHeaderField: "accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    print("\u{1F5D1} DELETE book status code: \(httpResponse.statusCode)")
    if let responseString = String(data: data, encoding: .utf8) {
        print("\u{1F5D1} DELETE book response body: \(responseString)")
    }
    if !(200...299).contains(httpResponse.statusCode) {
        throw NSError(domain: "BookDeleteError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete book"])
    }
}

func addToWishlistAPI(bookId: UUID) async throws {
    guard let token = try? KeychainManager.shared.getToken() else {
        throw URLError(.userAuthenticationRequired)
    }
    guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/wishlists") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["bookId": bookId.uuidString]
    let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
    
    request.httpBody = jsonData
    
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
    if let responseString = String(data: data, encoding: .utf8) {
        print("\u{1F4E5} Server response body: \(responseString)")
    }

    if (200...299).contains(httpResponse.statusCode) {
        print("✅ Book added to wishlist")
    } else {
        do {
            let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
            print("❌ Error adding to wishlist: \(errorResponse.errorMessage)")
            throw NSError(domain: "AddToWishlistError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
        } catch {
            let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error adding to wishlist (raw): \(rawErrorMessage)")
            print("Underlying decoding error (if any):")
            error.logDetails()
            throw NSError(domain: "AddToWishlistError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
        }
    }
}
func removeWishListApi(bookId:UUID)async throws{
    guard let token = try? KeychainManager.shared.getToken() else {
        throw URLError(.userAuthenticationRequired)
    }
    guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/wishlists/books/" + bookId.uuidString) else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
    if let responseString = String(data: data, encoding: .utf8) {
        print("\u{1F4E5} Server response body: \(responseString)")
    }

    if (200...299).contains(httpResponse.statusCode) {
        print("✅ Book removed from wishlist")
    } else {
        do {
            let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
            print("❌ Error removing from wishlist: \(errorResponse.errorMessage)")
            throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
        } catch {
            let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Error removing from wishlist (raw): \(rawErrorMessage)")
            print("Underlying decoding error (if any):")
            error.logDetails()
            throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
        }
    }

}
func getWishList()async throws -> [BookModel]{
    do {
        // Get authentication token and library ID
        guard let token = try? KeychainManager.shared.getToken() else {
            throw BookFetchError.tokenMissing
        }
        
        let libraryIdString = try KeychainManager.shared.getLibraryId()
        print("Using library ID from keychain: \(libraryIdString)")
        
        // Create URL request
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/wishlists/my?limit=200") else {
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
        let booksResponse = try JSONUtility.shared.decode(PaginatedResponse<[WishlistModel]>.self, from: data)
        
        // Process books if needed
        let processedBooks = booksResponse.data.map { res in
            var mutableBook = res.book
            return mutableBook
        }
        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Book removed from wishlist")
        return processedBooks
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error removing from wishlist: \(errorResponse.errorMessage)")
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error removing from wishlist (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
            return []
        }
        
    }
}

class ReviewHandler{
    static let shared = ReviewHandler()
    
    
    func createReview(rating:Int,bookId:UUID,comment:String) async throws -> ReviewModel?{
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/reviews") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["bookId": bookId.uuidString,"rating":rating,"comment":comment]
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }
        let booksResponse = try JSONUtility.shared.decode(ReviewModel.self, from: data)

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Created Review")
            return booksResponse
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error creating review: \(errorResponse.errorMessage)")
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error creating review (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }

    }
    func getReview(bookId: UUID)async throws -> [ReviewModel]{
        do {
            // Get authentication token and library ID
            guard let token = try? KeychainManager.shared.getToken() else {
                throw BookFetchError.tokenMissing
            }
            
            
            // Create URL request
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/reviews/book/\(bookId.uuidString)?page=1&limit=100&sortBy=reviewed_at&sortOrder=asc") else {
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
            let booksResponse = try JSONUtility.shared.decode(PaginatedResponse<[ReviewModel]>.self, from: data)
            
            // Process books if needed
            let processedBooks = booksResponse.data.map { res in
                return res
            }
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ got review")
                return processedBooks
            } else {
                do {
                    let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                    print("❌ Error getting review: \(errorResponse.errorMessage)")
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
                } catch {
                    let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Error fetching review (raw): \(rawErrorMessage)")
                    print("Underlying decoding error (if any):")
                    error.logDetails()
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
                }
            }
            
        }
    }

}

class BorrowHandler{
    static let shared = BorrowHandler()
    var borrowCache:[BorrowModel] = []
    
    func borrow(bookId:UUID,userId:UUID)async throws -> BorrowModel?{
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/borrow-transactions") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["bookId": bookId.uuidString,"userId": userId.uuidString]
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }
        let booksResponse = try JSONUtility.shared.decode(BorrowModel.self, from: data)

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Created Review")
            borrowCache = []
            return booksResponse
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error creating review: \(errorResponse.errorMessage)")
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error creating review (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }

    }
    func getBorrows()async throws -> [BorrowModel]{
        do {
            // Get authentication token and library ID
            guard let token = try? KeychainManager.shared.getToken() else {
                throw BookFetchError.tokenMissing
            }
            
            
            // Create URL request
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/borrow-transactions?limit=200&sortBy=borrow_date&sortOrder=asc") else {
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
            let booksResponse = try JSONUtility.shared.decode(PaginatedResponse<[BorrowModel]>.self, from: data)
            
            // Process books if needed
            let processedBooks = booksResponse.data.map { res in
                return res
            }
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ got review")
                borrowCache = processedBooks
                return processedBooks
            } else {
                do {
                    let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                    print("❌ Error getting review: \(errorResponse.errorMessage)")
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
                } catch {
                    let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Error fetching review (raw): \(rawErrorMessage)")
                    print("Underlying decoding error (if any):")
                    error.logDetails()
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
                }
            }
        }
    }
    func cancelBorrow(_ borrowId: UUID) async throws {
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/borrow-transactions/\(borrowId.uuidString)/cancel") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Book removed from wishlist")
            borrowCache = borrowCache.filter{$0.id != borrowId}
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error removing from wishlist: \(errorResponse.errorMessage)")
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error removing from wishlist (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }
    }
    func returnBorrow(_ borrowId: UUID) async throws {
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/borrow-transactions/\(borrowId.uuidString)/return") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Book removed from wishlist")
            borrowCache = borrowCache.filter{$0.id != borrowId}
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error removing from wishlist: \(errorResponse.errorMessage)")
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error removing from wishlist (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }

    }
    func getBorrowForBookId(_ bookId: UUID)async throws -> BorrowModel? {
        let borrows = try await getBorrows()
        return borrows.first { $0.book_id == bookId }
    }

}

class ReservationHandler{
    static let shared = ReservationHandler()
    var borrowCache:[ReservationModel] = []
    
    func reserve(bookId:UUID)async throws -> ReservationModel?{
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/reservations") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["bookId": bookId.uuidString]
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }
        let booksResponse = try JSONUtility.shared.decode(ReservationModel.self, from: data)

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Created Review")
            borrowCache = []
            return booksResponse
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error creating review: \(errorResponse.errorMessage)")
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error creating review (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "CreateReviewError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }

    }
    func getReservations()async throws -> [ReservationModel]{
        do {
            // Get authentication token and library ID
            guard let token = try? KeychainManager.shared.getToken() else {
                throw BookFetchError.tokenMissing
            }
            
            
            // Create URL request
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/reservations?limit=200&sortBy=borrow_date&sortOrder=asc") else {
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
            let booksResponse = try JSONUtility.shared.decode(PaginatedResponse<[ReservationModel]>.self, from: data)
            
            // Process books if needed
            let processedBooks = booksResponse.data.map { res in
                return res
            }
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ got review")
                borrowCache = processedBooks
                return processedBooks
            } else {
                do {
                    let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                    print("❌ Error getting review: \(errorResponse.errorMessage)")
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
                } catch {
                    let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Error fetching review (raw): \(rawErrorMessage)")
                    print("Underlying decoding error (if any):")
                    error.logDetails()
                    throw NSError(domain: "ReviewFetchError", code: httpResponse.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
                }
            }
        }
    }
    func cancelReservation(_ borrowId: UUID) async throws {
        guard let token = try? KeychainManager.shared.getToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/reservations/\(borrowId.uuidString)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("\u{1F4E5} Server response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("\u{1F4E5} Server response body: \(responseString)")
        }

        if (200...299).contains(httpResponse.statusCode) {
            print("✅ Book removed from wishlist")
            borrowCache = borrowCache.filter{$0.id != borrowId}
        } else {
            do {
                let errorResponse = try JSONUtility.shared.decode(ErrorResponse.self, from: data)
                print("❌ Error removing from wishlist: \(errorResponse.errorMessage)")
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorResponse.errorMessage])
            } catch {
                let rawErrorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error removing from wishlist (raw): \(rawErrorMessage)")
                print("Underlying decoding error (if any):")
                error.logDetails()
                throw NSError(domain: "RemoveFromWishlistError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: rawErrorMessage])
            }
        }
    }
    func getReservationForBookId(_ bookId: UUID)async throws -> ReservationModel? {
        let borrows = try await getReservations()
        return borrows.first { $0.book_id == bookId }
    }

}

class AnalyticsHandler {
    static let shared = AnalyticsHandler()
    
    private var analyticsCache: LibraryAnalytics?
    private var lastFetchTime: Date?
    private var isFetching = false
    
    // Cache expiration time - 10 minutes
    private let cacheExpirationInterval: TimeInterval = 600
    
    // UserDefaults keys for persistence
    private let analyticsKey = "cached_analytics_data"
    private let timestampKey = "analytics_fetch_timestamp"
    
    init() {
        // Load cached data from disk on startup
        loadCacheFromDisk()
    }
    
    // Check if cache is valid (exists and not expired)
    private var isCacheValid: Bool {
        guard let cache = analyticsCache, let fetchTime = lastFetchTime else {
            return false
        }
        
        let cacheAge = Date().timeIntervalSince(fetchTime)
        return cacheAge < cacheExpirationInterval
    }
    
    // Load cache from disk (UserDefaults)
    private func loadCacheFromDisk() {
        let defaults = UserDefaults.standard
        
        // Try to load timestamp first
        if let timestamp = defaults.object(forKey: timestampKey) as? Date {
            lastFetchTime = timestamp
            
            // Only load analytics data if timestamp is valid (not expired)
            let cacheAge = Date().timeIntervalSince(timestamp)
            if cacheAge < cacheExpirationInterval {
                if let cachedData = defaults.data(forKey: analyticsKey) {
                    do {
                        let decoder = JSONDecoder()
                        analyticsCache = try decoder.decode(LibraryAnalytics.self, from: cachedData)
                        print("📊 Loaded analytics cache from disk, age: \(Int(cacheAge)) seconds")
                    } catch {
                        print("📊 Error decoding cached analytics: \(error.localizedDescription)")
                        // If decode fails, clear the cache
                        defaults.removeObject(forKey: analyticsKey)
                        defaults.removeObject(forKey: timestampKey)
                    }
                }
            } else {
                print("📊 Cached analytics on disk is expired")
            }
        }
    }
    
    // Save cache to disk (UserDefaults)
    private func saveCacheToDisk() {
        guard let cache = analyticsCache, let timestamp = lastFetchTime else {
            return
        }
        
        let defaults = UserDefaults.standard
        
        // Save timestamp
        defaults.set(timestamp, forKey: timestampKey)
        
        // Save analytics data
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cache)
            defaults.set(data, forKey: analyticsKey)
            print("📊 Saved analytics cache to disk")
        } catch {
            print("📊 Error encoding analytics for cache: \(error.localizedDescription)")
        }
    }
    
    // Fetch data, using cache if available and not expired
    func fetchLibraryAnalytics() async throws -> LibraryAnalytics {
        // Return cached data if available and not expired
        if isCacheValid {
            print("📊 Using cached analytics data")
            return analyticsCache!
        }
        
        // If already fetching, wait for the result
        if isFetching {
            // Wait a bit and check if cache is available
            for _ in 0..<10 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                if let cache = analyticsCache {
                    return cache
                }
            }
        }
        
        // No valid cache, fetch from network
        return try await fetchFreshAnalytics()
    }
    
    // Force refresh data from network
    func refreshAnalytics() async throws -> LibraryAnalytics {
        return try await fetchFreshAnalytics()
    }
    
    // Internal method to fetch fresh data from network
    private func fetchFreshAnalytics() async throws -> LibraryAnalytics {
        isFetching = true
        
        do {
            // Get authentication token and library ID
            guard let token = try? KeychainManager.shared.getToken() else {
                throw URLError(.userAuthenticationRequired)
            }
            
            let libraryIdString = try KeychainManager.shared.getLibraryId()
            print("📊 Fetching fresh analytics for library ID: \(libraryIdString)")
            
            // Create URL request
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/analytics?library_id=\(libraryIdString)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "accept")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Make the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Decode the response
            let analyticsResponse = try JSONUtility.shared.decode(AnalyticsResponse.self, from: data)
            
            // Cache the result
            self.analyticsCache = analyticsResponse.data
            self.lastFetchTime = Date()
            
            // Save to disk
            saveCacheToDisk()
            
            print("📊 Analytics data fetched and cached successfully")
            isFetching = false
            
            return analyticsResponse.data
        } catch {
            isFetching = false
            print("Error fetching library analytics:")
            error.logDetails()
            throw error
        }
    }
    
    // Prefetch data in background
    func prefetchAnalyticsInBackground() {
        Task {
            do {
                _ = try await fetchLibraryAnalytics()
            } catch {
                print("Background prefetch of analytics failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Return cached analytics if valid
    func getCachedAnalytics() -> LibraryAnalytics? {
        if isCacheValid {
            return analyticsCache
        }
        return nil
    }
    
    // Clear the cache (useful for testing or logout)
    func clearCache() {
        analyticsCache = nil
        lastFetchTime = nil
        
        // Clear disk cache
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: analyticsKey)
        defaults.removeObject(forKey: timestampKey)
        print("📊 Analytics cache cleared")
    }
}

