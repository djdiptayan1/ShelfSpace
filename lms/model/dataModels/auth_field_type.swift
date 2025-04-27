import SwiftUI

enum AuthFieldType {
    case memberId
    case email
    case password
    case confirmPassword
    case name
    case phone
    case age
    case gender
}

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: T
    let pagination: Pagination
}

/// Pagination information returned by the API
struct Pagination: Decodable {
    let totalItems: Int
    let currentPage: Int
    let itemsPerPage: Int
    let totalPages: Int
}
