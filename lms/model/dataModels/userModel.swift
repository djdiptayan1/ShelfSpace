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
    let email: String
    let role: UserRole
    let name: String
    var profileImage: Data?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case name
        case profileImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        role = try container.decode(UserRole.self, forKey: .role)
        name = try container.decode(String.self, forKey: .name)
        profileImage = try container.decodeIfPresent(Data.self, forKey: .profileImage)
    }
    
    init(id: UUID, email: String, role: UserRole, name: String, profileImage: Data? = nil) {
        self.id = id
        self.email = email
        self.role = role
        self.name = name
        self.profileImage = profileImage
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
