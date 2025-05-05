//
//  BorrowModel.swift
//  lms
//
//  Created by dark on 05/05/25.
//

import Foundation

struct BorrowModel: Codable,Identifiable {
    let id: UUID
    let user_id:UUID
    let book_id:UUID
    let borrow_date:Date
    let return_date:Date?
    let status:BorrowStatus
    
    enum CodingKeys: String,CodingKey {
        case id = "borrow_id"
        case user_id
        case book_id
        case borrow_date
        case return_date
        case status
    }
}


enum BorrowStatus :String,Codable{
  case borrowed = "borrowed"
  case returned = "returned"
  case overdue = "overdue"
  case requested = "requested"
    
}
