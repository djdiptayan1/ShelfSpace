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
            
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
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

            guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }

            // Debug print the response data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
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
func fetchUser() {
    
}

func fetchGenres(completion: @escaping (Result<[String], Error>) -> Void) {
    Task {
        do {
            // Use 'supabase' instead of 'client'
            let response = try await supabase
                .from("genres")
                .select("name")
                .execute()

            let data = response.data
            let decoder = JSONDecoder()

            struct GenreResponse: Codable {
                let name: String
            }

            let genreResponse = try decoder.decode([GenreResponse].self, from: data)
            let genres = genreResponse.map { $0.name }

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
            let response = try await supabase
                .from("authors")
                .select("name")
                .execute()

            let data = response.data
            let decoder = JSONDecoder()
        }
    }
}

func uploadBooks() {
    @Binding var bookData: BookData
    print("Uploading books...")
    Task {
        do {
            let token = try KeychainManager.shared.getToken()
            
            guard let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/books") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Prepare the request body
//            let requestBody: [String: Any] = [
//                "library_id": "69d0dbf0-5e5c-4117-afeb-b43aa1d950cb", // You might want to make this dynamic
//                "title": bookData.bookTitle,
//                "isbn": bookData.isbn,
//                "description": bookData.description,
//                "total_copies": bookData.totalCopies,
//                "available_copies": bookData.availableCopies,
//                "reserved_copies": bookData.reservedCopies,
//                "author_ids": getAuthorIds(), // You'll need to implement this function to get author IDs
//                "genre_ids": getCategoryIds(), // You'll need to implement this function to get genre/category IDs
//                "published_date": formatDate(bookData.publishedDate),
//                "publisher": bookData.publisher,
//                "language": bookData.language
//            ]
            
            // Convert the dictionary to JSON data
//            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
//            request.httpBody = jsonData
            
            // Perform the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Success
                print("Book uploaded successfully")
                
                // Process response if needed
                if let responseJSON = try? JSONSerialization.jsonObject(with: data) {
                    print("Response: \(responseJSON)")
                }
                
                // Handle success (e.g., show success message, navigate back)
                DispatchQueue.main.async {
                    // Update UI or navigate
//                    self.showSuccessAlert = true
                }
            } else {
                // Handle error
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error uploading book: \(httpResponse.statusCode), \(errorMessage)")
                throw NSError(domain: "BookUploadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        } catch {
            // Handle error
            print("Error uploading book: \(error.localizedDescription)")
            DispatchQueue.main.async {
                // Update UI to show error
//                self.errorMessage = error.localizedDescription
//                self.showErrorAlert = true
            }
        }
    }
}
private func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
}
