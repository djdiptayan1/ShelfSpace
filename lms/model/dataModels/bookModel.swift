//
//  BookModel.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import UIKit

struct BookModel: Identifiable, Codable {
    let id: UUID                   // book_id
    let libraryId: UUID           // library_id

    var title: String             // title
    var isbn: String?             // isbn
    var description: String?      // description

    var totalCopies: Int          // total_copies
    var availableCopies: Int      // available_copies
    var reservedCopies: Int       // reserved_copies (defaults to 0 if not provided)

    var authorIds: [UUID]         // author_ids
    var authorNames: [String]?    // For UI only; not in DB
    var genreIds: [UUID]          // genre_ids
    var genreNames: [String]?     // For UI only; not in DB

    var publishedDate: Date?      // published_date
    var addedOn: Date?            // added_on
    var updatedAt: Date?          // updated_at

    var coverImageUrl: String?    // Cloud storage URL
    var coverImageData: Data?     // Local cache (for UI only)
    
    var bookCover: UIImage? = nil

    enum CodingKeys: String, CodingKey {
        case id = "book_id"
        case libraryId = "library_id"
        case title
        case isbn
        case description
        case totalCopies = "total_copies"
        case availableCopies = "available_copies"
        case reservedCopies = "reserved_copies"
        case authorIds = "author_ids"
        case authorNames = "author_names"
        case genreIds = "genre_ids"
        case genreNames = "genre_names"
        case publishedDate = "published_date"
        case addedOn = "added_on"
        case updatedAt = "updated_at"
        case coverImageUrl = "cover_image_url"
        case coverImageData = "cover_image_data"
    }

    // Custom initializer to set default value for reservedCopies if needed
    init(
        id: UUID,
        libraryId: UUID,
        title: String,
        isbn: String? = nil,
        description: String? = nil,
        totalCopies: Int,
        availableCopies: Int,
        reservedCopies: Int = 0,
        authorIds: [UUID],
        authorNames: [String]? = nil,
        genreIds: [UUID],
        genreNames: [String]? = nil,
        publishedDate: Date? = nil,
        addedOn: Date? = nil,
        updatedAt: Date? = nil,
        coverImageUrl: String? = nil,
        coverImageData: Data? = nil
    ) {
        self.id = id
        self.libraryId = libraryId
        self.title = title
        self.isbn = isbn
        self.description = description
        self.totalCopies = totalCopies
        self.availableCopies = availableCopies
        self.reservedCopies = reservedCopies
        self.authorIds = authorIds
        self.authorNames = authorNames
        self.genreIds = genreIds
        self.genreNames = genreNames
        self.publishedDate = publishedDate
        self.addedOn = addedOn
        self.updatedAt = updatedAt
        self.coverImageUrl = coverImageUrl
        self.coverImageData = coverImageData
    }
}

struct BooksResponse: Codable {
    let data: [BookModel]
    let pagination: Pagination
    
    struct Pagination: Codable {
        let totalItems: Int
        let currentPage: Int
        let itemsPerPage: Int
        let totalPages: Int
    }
}


enum BookFetchError: Error {
    case tokenMissing
    case libraryIdMissing
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .tokenMissing:
            return "Authentication token not found. Please log in again."
        case .libraryIdMissing:
            return "Library ID not found. Please log in again."
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
