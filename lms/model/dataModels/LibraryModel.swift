//
//  LibraryModel.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation

struct Library: Identifiable, Codable {
    let id: String
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "library_id"
        case name
        case address
        case city
        case state
        case country
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}