//
//  userModel.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//

import Foundation

enum UserRole: String, Codable {
    case admin
    case librarian
    case member
}

struct User: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var email: String
    let role: UserRole
    var name: String
    var is_active: Bool
    var library_id: String
    var borrowed_book_ids: [UUID]
    var reserved_book_ids: [UUID]
    var wishlist_book_ids: [UUID]
    var created_at: String
    var updated_at: String
    var age: Int?
    var phone_number: String?
    var interests: [String]?
    var gender: String?
    var profileImage: Data?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case email
        case role
        case name
        case is_active
        case library_id
        case borrowed_book_ids
        case reserved_book_ids
        case wishlist_book_ids
        case created_at
        case updated_at
        case age
        case phone_number
        case interests
        case gender
        case profileImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        role = try container.decode(UserRole.self, forKey: .role)
        name = try container.decode(String.self, forKey: .name)
        is_active = try container.decode(Bool.self, forKey: .is_active)
        library_id = try container.decode(String.self, forKey: .library_id)
        borrowed_book_ids = try container.decode([UUID].self, forKey: .borrowed_book_ids)
        reserved_book_ids = try container.decode([UUID].self, forKey: .reserved_book_ids)
        wishlist_book_ids = try container.decode([UUID].self, forKey: .wishlist_book_ids)
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try container.decode(String.self, forKey: .updated_at)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        phone_number = try container.decodeIfPresent(String.self, forKey: .phone_number)
        interests = try container.decodeIfPresent([String].self, forKey: .interests)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        profileImage = try container.decodeIfPresent(Data.self, forKey: .profileImage)
    }
    
    init(id: UUID, email: String, role: UserRole, name: String, is_active: Bool, library_id: String,
         borrowed_book_ids: [UUID] = [], reserved_book_ids: [UUID] = [], wishlist_book_ids: [UUID] = [],
         created_at: String = "", updated_at: String = "", age: Int? = nil, phone_number: String? = nil,
         interests: [String]? = nil, gender: String? = nil, profileImage: Data? = nil) {
        self.id = id
        self.email = email
        self.role = role
        self.name = name
        self.is_active = is_active
        self.library_id = library_id
        self.borrowed_book_ids = borrowed_book_ids
        self.reserved_book_ids = reserved_book_ids
        self.wishlist_book_ids = wishlist_book_ids
        self.created_at = created_at
        self.updated_at = updated_at
        self.age = age
        self.phone_number = phone_number
        self.interests = interests
        self.gender = gender
        self.profileImage = profileImage
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
