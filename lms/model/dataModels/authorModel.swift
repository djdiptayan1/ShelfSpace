//
//  authorModel.swift
//  lms
//
//  Created by Diptayan Jash on 02/05/25.
//

import Foundation

struct AuthorModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bio: String?             // Optional, matches `bio text null`
    var bookIds: [UUID] = []     // Default empty array, matches `book_ids uuid[] null default array[]::uuid[]`
    var createdAt: String?          // Matches `timestamp with time zone`
    var updatedAt: String?          // Matches `timestamp with time zone`
    
    enum CodingKeys: String, CodingKey {
        case id = "author_id"
        case name
        case bio
        case bookIds = "book_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
