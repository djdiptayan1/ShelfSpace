//
//  BorrowModel.swift
//  lms
//
//  Created by dark on 05/05/25.
//

import Foundation

struct BorrowModel: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID // Keep the user's ID if needed
    let book_id: UUID
    let borrow_date: Date
    let return_date: Date?
    let status: BorrowStatus
    let book: BookModel? // Keep the nested book object

    // Define CodingKeys to map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case id = "borrow_id"
        case user_id // Assumes JSON key is "user_id"
        case book_id // Assumes JSON key is "book_id"
        case borrow_date // Assumes JSON key is "borrow_date"
        case return_date // Assumes JSON key is "return_date"
        case status // Assumes JSON key is "status"
        case book // Assumes JSON key is "book" (for the nested BookModel)
        // --- REMOVED 'case user' ---
        // By removing 'case user', the decoder will ignore the "user" object in the JSON
    }

    // Equatable conformance based on ID
    static func == (lhs: BorrowModel, rhs: BorrowModel) -> Bool {
        return lhs.id == rhs.id
    }
}


// BorrowStatus enum remains the same
enum BorrowStatus: String, Codable, CaseIterable { // Added CaseIterable from your UI code
  case borrowed = "borrowed"
  case returned = "returned"
  case overdue = "overdue"
  case requested = "requested"
}
