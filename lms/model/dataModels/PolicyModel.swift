//
//  PolicyModel.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
// PolicyModel.swift

import Foundation

struct Policy: Codable, Identifiable {
    var id: UUID? // This will map to policy_id in the response
    var policy_id: UUID?
    var library_id: UUID
    var max_borrow_days: Int
    var fine_per_day: Decimal
    var max_books_per_user: Int
    var reservation_expiry_days: Int
    var created_at: Date?
    var updated_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case policy_id
        case library_id
        case max_borrow_days
        case fine_per_day
        case max_books_per_user
        case reservation_expiry_days
        case created_at
        case updated_at
    }
    
    // This initializer is used when creating a new policy
    init(library_id: UUID, max_borrow_days: Int, fine_per_day: Decimal, max_books_per_user: Int, reservation_expiry_days: Int) {
        self.library_id = library_id
        self.max_borrow_days = max_borrow_days
        self.fine_per_day = fine_per_day
        self.max_books_per_user = max_books_per_user
        self.reservation_expiry_days = reservation_expiry_days
    }
    
    // This initializer is used when decoding a policy from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode policy_id first, fall back to id if needed
        if let policyId = try? container.decode(UUID.self, forKey: .policy_id) {
            self.policy_id = policyId
            self.id = policyId
        } else if let id = try? container.decode(UUID.self, forKey: .id) {
            self.id = id
            self.policy_id = id
        } else {
            self.id = nil
            self.policy_id = nil
        }
        
        self.library_id = try container.decode(UUID.self, forKey: .library_id)
        self.max_borrow_days = try container.decode(Int.self, forKey: .max_borrow_days)
        
        // Handle fine_per_day which could be a string or decimal in the API response
        if let fineString = try? container.decode(String.self, forKey: .fine_per_day),
           let fineValue = Decimal(string: fineString) {
            self.fine_per_day = fineValue
        } else {
            self.fine_per_day = try container.decode(Decimal.self, forKey: .fine_per_day)
        }
        
        self.max_books_per_user = try container.decode(Int.self, forKey: .max_books_per_user)
        self.reservation_expiry_days = try container.decode(Int.self, forKey: .reservation_expiry_days)
        
        // Date fields are optional
        self.created_at = try? container.decode(Date.self, forKey: .created_at)
        self.updated_at = try? container.decode(Date.self, forKey: .updated_at)
    }
    
    // This function is used when encoding a policy to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let policyId = policy_id {
            try container.encode(policyId, forKey: .policy_id)
        }
        
        try container.encode(library_id, forKey: .library_id)
        try container.encode(max_borrow_days, forKey: .max_borrow_days)
        try container.encode(fine_per_day, forKey: .fine_per_day)
        try container.encode(max_books_per_user, forKey: .max_books_per_user)
        try container.encode(reservation_expiry_days, forKey: .reservation_expiry_days)
        
        if let createdAt = created_at {
            try container.encode(createdAt, forKey: .created_at)
        }
        
        if let updatedAt = updated_at {
            try container.encode(updatedAt, forKey: .updated_at)
        }
    }
}
