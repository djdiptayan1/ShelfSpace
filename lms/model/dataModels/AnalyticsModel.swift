import Foundation
import UIKit

// MARK: - Main Analytics Model
struct LibraryAnalytics: Codable {
    let dashboard: DashboardData
    let details: DetailsData
}

// MARK: - Analytics Response
struct AnalyticsResponse: Codable {
    let success: Bool
    let data: LibraryAnalytics
}

// MARK: - Dashboard Summary Data
struct DashboardData: Codable {
    let fineReports: FineReports
    let circulationStatistics: CirculationStatistics
    let mostBorrowedBook: AnalyticsBookModel?
    let catalogInsights: CatalogInsights
}

// MARK: - Detailed Analytics Data
struct DetailsData: Codable {
    let fines: FinesDetail
    let overdueBooks: OverdueBooks
    let circulation: CirculationDetail
    let books: BooksDetail
    let newBooks: NewBooksDetail
    let borrowedBooks: BorrowedBooksDetail
}

// MARK: - Analytics Book Model
struct AnalyticsBookModel: Codable {
    let bookId: UUID
    let libraryId: UUID
    let title: String
    let isbn: String?
    let description: String?
    let totalCopies: Int
    let availableCopies: Int
    let reservedCopies: Int
    let authorIds: [UUID]
    let genreIds: [UUID]
    let publishedDate: String?
    let addedOn: String?
    let updatedAt: String?
    let coverImageUrl: String?
    let genreNames: [String]?
    let borrowCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case bookId = "book_id"
        case libraryId = "library_id"
        case title
        case isbn
        case description
        case totalCopies = "total_copies"
        case availableCopies = "available_copies"
        case reservedCopies = "reserved_copies"
        case authorIds = "author_ids"
        case genreIds = "genre_ids"
        case publishedDate = "published_date"
        case addedOn = "added_on"
        case updatedAt = "updated_at"
        case coverImageUrl = "cover_image_url"
        case genreNames = "genre_names"
        case borrowCount = "borrowCount"
    }
    
    // Convert to regular BookModel
    func toBookModel() -> BookModel {
        return BookModel(
            id: bookId,
            libraryId: libraryId,
            title: title,
            isbn: isbn,
            description: description,
            totalCopies: totalCopies,
            availableCopies: availableCopies,
            reservedCopies: reservedCopies,
            authorIds: authorIds,
            genreIds: genreIds,
            genreNames: genreNames,
            publishedDate: publishedDate != nil ? ISO8601DateFormatter().date(from: publishedDate!) : nil,
            addedOn: addedOn != nil ? ISO8601DateFormatter().date(from: addedOn!) : nil,
            updatedAt: updatedAt != nil ? ISO8601DateFormatter().date(from: updatedAt!) : nil,
            coverImageUrl: coverImageUrl
        )
    }
}

// MARK: - Fine Reports
struct FineReports: Codable {
    let totalFines: Int
    let overdueBooks: Int
}

// MARK: - Circulation Statistics
struct CirculationStatistics: Codable {
    let dailyCirculation: [DailyCirculation]
    let totalCirculation: Int
}

struct DailyCirculation: Codable {
    let date: String
    let dayOfWeek: String
    let count: Int
}

// MARK: - Catalog Insights
struct CatalogInsights: Codable {
    let totalBooks: Int
    let newBooks: Int
    let borrowedBooks: Int
}

// MARK: - Fines Detail
struct FinesDetail: Codable {
    let totalFines: Int
    let breakdown: FineBreakdown
    let monthlyTrend: FineMonthlyTrend
}

struct FineBreakdown: Codable {
    let collected: Int
    let pending: Int
}

struct FineMonthlyTrend: Codable {
    let currentMonth: Int
    let lastMonth: Int
    let twoMonthsAgo: Int
    let threeMonthsAgo: Int
}

// MARK: - Overdue Books
struct OverdueBooks: Codable {
    let total: Int
    let byDuration: OverdueDuration
    let byCategory: [String: Int]
    
    private enum CodingKeys: String, CodingKey {
        case total, byDuration, byCategory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        byDuration = try container.decode(OverdueDuration.self, forKey: .byDuration)
        
        // Handle potentially empty dictionary or different formats
        if let categories = try? container.decode([String: Int].self, forKey: .byCategory) {
            byCategory = categories
        } else {
            byCategory = [:]
        }
    }
}

struct OverdueDuration: Codable {
    let days1to7: Int
    let days8to14: Int
    let days15Plus: Int
    
    enum CodingKeys: String, CodingKey {
        case days1to7 = "1-7Days"
        case days8to14 = "8-14Days"
        case days15Plus = "15+Days"
    }
}

// MARK: - Circulation Detail
struct CirculationDetail: Codable {
    let total: Int
    let daily: [DailyCirculation]
    let mostBorrowedBook: AnalyticsBookModel?
    let monthlyTrends: MonthlyTrend
}

struct MonthlyTrend: Codable {
    let currentMonth: Int
    let lastMonth: Int
    let growthRate: String
}

// MARK: - Books Detail
struct BooksDetail: Codable {
    let total: Int
    let byGenre: [String: Int]
    let byStatus: BookStatusCounts
    let growthTrend: GrowthTrend
}

struct BookStatusCounts: Codable {
    let available: Int
    let borrowed: Int
    let reserved: Int
}

struct GrowthTrend: Codable {
    let currentMonth: Int
    let lastMonth: Int
    let twoMonthsAgo: Int
    let threeMonthsAgo: Int
}

// MARK: - New Books Detail
struct NewBooksDetail: Codable {
    let total: Int
    let recent: [AnalyticsBookModel]
    let byCategory: [String: Int]
    
    private enum CodingKeys: String, CodingKey {
        case total, recent, byCategory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        recent = try container.decode([AnalyticsBookModel].self, forKey: .recent)
        
        // Handle potentially empty dictionary
        if let categories = try? container.decode([String: Int].self, forKey: .byCategory) {
            byCategory = categories
        } else {
            byCategory = [:]
        }
    }
}

// MARK: - Borrowed Books Detail
struct BorrowedBooksDetail: Codable {
    let total: Int
    let dueDates: DueDates
    let popularCategories: [String: Int]
    let trend: BorrowTrend
}

struct DueDates: Codable {
    let overdue: Int
    let today: Int
    let thisWeek: Int
    let nextWeek: Int
}

struct BorrowTrend: Codable {
    let currentMonth: Int
    let lastMonth: Int
    let twoMonthsAgo: Int
    let threeMonthsAgo: Int
} 