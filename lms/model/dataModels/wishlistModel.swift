//
//  wishlistModel.swift
//  lms
//
//  Created by dark on 04/05/25.
//

import Foundation

struct WishlistModel: Codable {
    var book_id:String
    var added_at:Date
    var book:BookModel
}

