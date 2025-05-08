import Foundation
import SwiftUI

// MARK: - Service Error
enum GeminiServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case apiError(String)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL was invalid."
        case .invalidResponse:
            return "The server gave an unexpected response."
        case .invalidData:
            return "The data format was incorrect."
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError(let message):
            return "Data Parsing Error: \(message)"
        }
    }
}

// MARK: - Mood Journey Data Models
struct MoodChoice: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
}

struct BookSuggestion: Identifiable {
    var id = UUID()
    var title: String
    var author: String?
    var reason: String

    // Custom initializer to clean up reason text if desired
    init(id: UUID = UUID(), title: String, author: String?, reason: String) {
        self.id = id
        self.title = title
        self.author = author
        // Basic cleanup for reason
        self.reason = reason
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini Specific Decodable Structs (Internal to Service or for decoding)

struct GeminiSubChoice: Decodable {
    let name: String
    let icon: String
}

struct GeminiBookSuggestionWithAuthor: Decodable {
    let title: String
    let author: String
    let reason: String
}

struct GeminiChatResponse: Decodable {
    let response_text: String
}


struct GeminiAPIResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]
            let role: String?
        }
        let content: Content?
        let finishReason: String?
        let index: Int?
        // let safetyRatings: [SafetyRating]?
    }
    let candidates: [Candidate]?
    // let promptFeedback: PromptFeedback?
}

// struct SafetyRating: Decodable {
//     let category: String
//     let probability: String // e.g., "NEGLIGIBLE", "LOW", "MEDIUM", "HIGH"
// }

// struct PromptFeedback: Decodable {
//     let safetyRatings: [SafetyRating]?
//     // blockReason, blockReasonMessage etc.
// }


// MARK: - Gemini API Error Response Structure

struct GeminiErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let code: Int
        let message: String
        let status: String
        // let details: [AnyDecodable]?
    }
    let error: ErrorDetail
}


// MARK: - Chat Models (Used by UI)

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    static func userMessage(_ content: String) -> ChatMessage {
        ChatMessage(content: content, isUser: true, timestamp: Date())
    }

    static func aiMessage(_ content: String) -> ChatMessage {
        ChatMessage(content: content, isUser: false, timestamp: Date())
    }
}
