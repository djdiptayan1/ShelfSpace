//
//  bookInfoFetch.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI

// MARK: - Book Info Models
struct BookInfo: Codable {
    let title: String
    let authors: [String]
    let description: String?
    let publishedDate: String?
    let publisher: String?
    let pageCount: Int?
    let categories: [String]?
    let language: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case authors
        case description
        case publishedDate
        case publisher
        case pageCount
        case categories
        case language
        case imageLinks
        case industryIdentifiers
    }
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

struct GoogleBooksResponse: Codable {
    let items: [BookItem]?
}

struct BookItem: Codable {
    let volumeInfo: BookInfo
}

// MARK: - Book Info Service
class BookInfoService {
    private let apiKey = "AIzaSyD757EQ0m_YAhPdNQbePryYZH8DUos9cbs"
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    func fetchBookInfo(isbn: String) async throws -> BookInfo? {
        let urlString = "\(baseURL)?q=isbn:\(isbn)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        return response.items?.first?.volumeInfo
    }
    
    func loadImage(from urlString: String) async throws -> UIImage? {
        var secureURLString = urlString
        if secureURLString.hasPrefix("http://") {
            secureURLString = secureURLString.replacingOccurrences(of: "http://", with: "https://")
        }

        guard let url = URL(string: secureURLString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }

    
    func loadCoverFromOpenLibrary(isbn: String) async throws -> (image: UIImage, url: String)? {
        let urlString = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            // Check if we got a valid image response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                return (image, urlString)  // Return both as a tuple
            }
            return nil
        } catch {
            print("Error fetching cover from OpenLibrary: \(error)")
            return nil
        }
    }
}
