//
//  ReviewModel.swift
//  lms
//
//  Created by dark on 05/05/25.
//

import Foundation

struct ReviewModel:Codable,Identifiable{
    let id:String
    let book_id:String
    let rating:Int
    let comment:String
    let user:ReviewUser?
    let book:ReviewBook?
    let reviewed_at:Date
    let user_id:UUID
    
    enum CodingKeys: String, CodingKey {
        case id = "review_id"
        case book_id
        case rating
        case comment
        case user
        case book
        case reviewed_at
        case user_id
    }
}
struct ReviewUser:Codable{
    let user_id:String
    let name:String
}
struct ReviewBook:Codable{
    let book_id:String
    let title:String
}
