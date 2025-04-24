//
//  bookModel.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation

struct BookModel: Identifiable, Codable {
    let id: UUID                    // book_id
    let libraryId: UUID            // library_id

    let title: String              // title
    let coverImageUrl: String?     // URL for cloud storage
    let coverImageData: Data?      // Local image data
    let isbn: String?              // isbn
    let description: String?       // description

    let totalCopies: Int           // total_copies
    let availableCopies: Int       // available_copies
    let reservedCopies: Int?       // reserved_copies (optional with default 0)

    let authorIds: [UUID]          // author_ids
    let authorNames: [String]      // author_names
    let genreIds: [UUID]           // genre_ids

    let publishedDate: Date?       // published_date
    let addedOn: Date?             // added_on

    enum CodingKeys: String, CodingKey {
        case id = "book_id"
        case libraryId = "library_id"
        case title
        case coverImageUrl = "cover_image_url"
        case coverImageData = "cover_image_data"
        case isbn
        case description
        case totalCopies = "total_copies"
        case availableCopies = "available_copies"
        case reservedCopies = "reserved_copies"
        case authorIds = "author_ids"
        case authorNames = "author_names"
        case genreIds = "genre_ids"
        case publishedDate = "published_date"
        case addedOn = "added_on"
    }
}
