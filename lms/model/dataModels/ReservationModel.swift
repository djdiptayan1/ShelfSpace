//
//  ReservationModel.swift
//  lms
//
//  Created by dark on 06/05/25.
//

import Foundation
struct ReservationModel: Codable,Identifiable {
    let id: UUID
    let user_id:UUID
    let book_id:UUID
    let reserved_at:Date
    let expires_at:Date
    let book:BookModel?
    
    enum CodingKeys: String,CodingKey {
        case id = "reservation_id"
        case user_id
        case book_id
        case reserved_at
        case expires_at
        case book
    }
}
