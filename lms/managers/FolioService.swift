import Foundation
import SwiftUI

class FolioService {
    static let shared = FolioService()
    private let apiKey = APIConfig.apiKey
    private let baseURL = APIConfig.baseURL

    private init() {}
    private func cleanJsonResponseString(_ rawString: String) -> String {
        var cleanedString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedString.hasPrefix("```json") && cleanedString.hasSuffix("```") {
            cleanedString = String(cleanedString.dropFirst(7).dropLast(3))
        } else if cleanedString.hasPrefix("```") && cleanedString.hasSuffix("```") {
            cleanedString = String(cleanedString.dropFirst(3).dropLast(3))
        }
        return cleanedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateSubChoices(for primaryMood: String) async throws -> [MoodChoice] {
        let prompt = """
            You are an AI assistant for a library app. Based on the primary mood "\(primaryMood)", suggest 3 related sub-themes or reading experiences as short phrases.
            For each suggestion, also include an appropriate SF Symbol name that represents that sub-theme visually.

            Your entire response MUST be a valid JSON array of objects. Each object must have a "name" (string) and an "icon" (string - SF Symbol name).
            Example:
            [
                {"name": "Sub-theme 1", "icon": "sf_symbol_name1"},
                {"name": "Sub-theme 2", "icon": "sf_symbol_name2"},
                {"name": "Sub-theme 3", "icon": "sf_symbol_name3"}
            ]
            Do NOT include any text, explanations, or markdown formatting outside of the JSON array itself.
            """

        let rawJsonResponseString = try await sendRequest(
            prompt: prompt, expectedMimeType: "application/json")
        print(
            "--- Raw response for SubChoices ---\n\(rawJsonResponseString)\n---------------------------------"
        )
        let cleanedJsonResponseString = cleanJsonResponseString(rawJsonResponseString)
        print(
            "--- Cleaned response for SubChoices ---\n\(cleanedJsonResponseString)\n---------------------------------"
        )

        do {
            let decoder = JSONDecoder()
            guard let jsonData = cleanedJsonResponseString.data(using: .utf8) else {
                print(
                    "Error converting cleaned JSON string to Data for SubChoices. Cleaned string was: '\(cleanedJsonResponseString)'"
                )
                throw GeminiServiceError.invalidData
            }
            let geminiSubChoices = try decoder.decode([GeminiSubChoice].self, from: jsonData)
            return geminiSubChoices.map { MoodChoice(name: $0.name, icon: $0.icon) }
        } catch {
            print("Parsing error for SubChoices. Original error: \(error)")
            print("Problematic JSON string for SubChoices was: '\(cleanedJsonResponseString)'")
            print("Falling back to dummy SubChoices for \(primaryMood).")
            return fallbackSubChoices(for: primaryMood)
        }
    }

    func generateBookSuggestions(primaryMood: String, subChoice: String) async throws
        -> [BookSuggestion]
    {
        let prompt = """
            You are a helpful AI assistant for a library app. Based on the primary mood "\(primaryMood)" and sub-theme "\(subChoice)", suggest 3 book titles.
            For each book, provide:
            1. The book title (string)
            2. The author's name (string)
            3. A compelling one-sentence reason why this book fits this specific mood journey (string)

            Your entire response MUST be a valid JSON array of objects. Each object must have "title", "author", and "reason" keys.
            Example:
            [
                {"title": "Book Title 1", "author": "Author Name 1", "reason": "Compelling reason 1"},
                {"title": "Book Title 2", "author": "Author Name 2", "reason": "Compelling reason 2"},
                {"title": "Book Title 3", "author": "Author Name 3", "reason": "Compelling reason 3"}
            ]
            Suggestions should be real books. Make reasons personalized. Do NOT include any text, explanations, or markdown formatting outside of the JSON array itself.
            """

        let rawJsonResponseString = try await sendRequest(
            prompt: prompt, expectedMimeType: "application/json")
        print(
            "--- Raw response for BookSuggestions ---\n\(rawJsonResponseString)\n------------------------------------"
        )
        let cleanedJsonResponseString = cleanJsonResponseString(rawJsonResponseString)
        print(
            "--- Cleaned response for BookSuggestions ---\n\(cleanedJsonResponseString)\n------------------------------------"
        )

        do {
            let decoder = JSONDecoder()
            guard let jsonData = cleanedJsonResponseString.data(using: .utf8) else {
                print(
                    "Error converting cleaned JSON string to Data for BookSuggestions. Cleaned string was: '\(cleanedJsonResponseString)'"
                )
                throw GeminiServiceError.invalidData
            }
            let geminiBookSuggestions = try decoder.decode(
                [GeminiBookSuggestionWithAuthor].self, from: jsonData)
            return geminiBookSuggestions.map {
                BookSuggestion(title: $0.title, author: $0.author, reason: $0.reason)
            }
        } catch {
            print(
                "Initial parsing error for BookSuggestions: \(error). Problematic JSON: '\(cleanedJsonResponseString)'"
            )
            let regexParsedSuggestions = parseBookSuggestionsWithRegex(cleanedJsonResponseString)
            if !regexParsedSuggestions.isEmpty {
                print(
                    "Successfully recovered \(regexParsedSuggestions.count) book suggestions via regex."
                )
                return regexParsedSuggestions
            }

            print("All parsing attempts failed for BookSuggestions. Falling back to dummy data.")
            return fallbackBookSuggestions(for: primaryMood, subChoice: subChoice)
        }
    }

    //    // Regex parser for book suggestions as a fallback
    //    private func parseBookSuggestionsWithRegex(_ jsonString: String) -> [BookSuggestion] {
    //        print("Attempting specialized regex fix for book suggestions JSON (with author)")
    //        var fixedArray: [BookSuggestion] = []
    //        // This pattern tries to find "title": "value", "author": "value", "reason": "value"
    //        // It's somewhat lenient with whitespace and assumes the fields appear in this order within an object.
    //        let pattern = #""title"\s*:\s*"([^"]*)"\s*,\s*"author"\s*:\s*"([^"]*)"\s*,\s*"reason"\s*:\s*"([^"]*)""#
    //
    //        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
    //            let nsString = jsonString as NSString
    //            let matches = regex.matches(in: jsonString, options: [], range: NSRange(location: 0, length: nsString.length))
    //
    //            for match in matches {
    //                if match.numberOfRanges >= 4 { // We expect 3 captured groups + the full match
    //                    let title = nsString.substring(with: match.range(at: 1))
    //                    let author = nsString.substring(with: match.range(at: 2))
    //                    let reason = nsString.substring(with: match.range(at: 3))
    //                    fixedArray.append(BookSuggestion(title: title, author: author, reason: reason))
    //                }
    //            }
    //        }
    //        if !fixedArray.isEmpty {
    //            print("Regex extracted \(fixedArray.count) book suggestions.")
    //        } else {
    //            print("Regex found no book suggestions in: \(jsonString.prefix(300))")
    //        }
    //        return fixedArray
    //    }

    // Handle book inquiries through chat
    func processBookInquiry(query: String, chatHistory: [ChatMessage] = []) async throws -> String {
        // Build context from chat history
        var conversationContext = ""
        if !chatHistory.isEmpty {
            conversationContext = "Previous conversation:\n"
            for message in chatHistory {
                let role = message.isUser ? "User" : "Assistant"
                conversationContext += "\(role): \(message.content)\n"
            }
            conversationContext += "\n"
        }

        let prompt = """
            You are a knowledgeable AI assistant for a library app called Folio. The user is asking about books, authors, or seeking recommendations.
            \(conversationContext)
            Current user query: "\(query)"

            Your entire response MUST be a valid JSON object.
            The JSON object should have a single key "response_text" whose value is a string containing your conversational reply.
            This reply string can contain markdown for formatting (e.g., *bold*, _italic_, - lists for bullet points, use \\n for newlines within the string).

            If the query is about a specific book, include: Title, Author, Brief plot summary (1-2 sentences), Genre, Themes (2-3 key themes), Publication Year. Optionally, notable awards. Conclude with why someone might enjoy it.
            If about an author, provide a brief bio and list 2-3 of their most notable works.
            If an ISBN, identify the book and provide details.
            If the query is a follow-up to previous questions, use the conversation history to provide a contextually appropriate response.
            If the query is too vague, ask clarifying questions.

            Example of your JSON output for a book query:
            {
                "response_text": "Ah, 'Dune'! That's a classic. \\n**Title:** Dune\\n**Author:** Frank Herbert\\n**Published:** 1965\\n**Genre:** Science Fiction\\n**Summary:** Set in the distant future, it follows young Paul Atreides whose family accepts stewardship of the dangerous desert planet Arrakis, the only source of the valuable spice melange. It's a tale of politics, religion, ecology, and human evolution.\\n**Themes:** Power, survival, destiny.\\nIt's a fantastic read if you enjoy epic world-building and complex characters!"
            }

            Example for an author:
            {
                "response_text": "Chetan Bhagat is a popular Indian author known for his relatable novels, often focusing on young Indians. Some of his famous books include:\\n- *Five Point Someone*\\n- *2 States: The Story of My Marriage*\\n- *Half Girlfriend*\\nHis writing style is generally simple and engaging."
            }

            For follow-up questions, reference the previous conversation and maintain a natural flow.

            Ensure the "response_text" is helpful and conversational. Keep information concise.
            """

        let rawJsonResponseString = try await sendRequest(
            prompt: prompt, expectedMimeType: "application/json")
        print(
            "--- Raw response for Chat Inquiry ---\n\(rawJsonResponseString)\n---------------------------------"
        )
        let cleanedJsonResponseString = cleanJsonResponseString(rawJsonResponseString)
        print(
            "--- Cleaned response for Chat Inquiry ---\n\(cleanedJsonResponseString)\n---------------------------------"
        )

        do {
            let decoder = JSONDecoder()
            guard let jsonData = cleanedJsonResponseString.data(using: .utf8) else {
                print(
                    "Error converting cleaned JSON string to Data for Chat. Cleaned string was: '\(cleanedJsonResponseString)'"
                )
                throw GeminiServiceError.invalidData
            }
            let chatResponse = try decoder.decode(GeminiChatResponse.self, from: jsonData)
            return chatResponse.response_text
        } catch {
            print("Parsing error for Chat response. Original error: \(error)")
            print("Problematic JSON string for Chat was: '\(cleanedJsonResponseString)'")
            if !cleanedJsonResponseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(
                "{")
                && !cleanedJsonResponseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            {
                print("Chat response was not JSON, returning cleaned text directly as a fallback.")
                return cleanedJsonResponseString
            }
            throw GeminiServiceError.parsingError(
                "Failed to parse chat JSON response: \(error.localizedDescription)")
        }
    }

    // Generate Book Club Insights
    func generateBookClubInsights(prompt: String) async throws -> BookClubInsights {
        let rawJsonResponseString = try await sendRequest(
            prompt: prompt, expectedMimeType: "application/json")
        print(
            "--- Raw response for Book Club Insights ---\n\(rawJsonResponseString)\n-----------------------------------"
        )
        let cleanedJsonResponseString = cleanJsonResponseString(rawJsonResponseString)
        print(
            "--- Cleaned response for Book Club Insights ---\n\(cleanedJsonResponseString)\n-----------------------------------"
        )

        do {
            let decoder = JSONDecoder()
            guard let jsonData = cleanedJsonResponseString.data(using: .utf8) else {
                throw GeminiServiceError.invalidResponse
            }
            let insights = try decoder.decode(BookClubInsights.self, from: jsonData)
            return insights
        } catch {
            print("Parsing error for Book Club Insights. Original error: \(error)")
            print("Problematic JSON string was: '\(cleanedJsonResponseString)'")

            // If JSON parsing fails, try a fallback with empty arrays
            throw GeminiServiceError.parsingError(
                "Failed to parse book club insights: \(error.localizedDescription)")
        }
    }

    // Common method to send requests to Gemini API
    private func sendRequest(prompt: String, expectedMimeType: String = "text/plain") async throws
        -> String
    {
        guard let url = URL(string: "\(baseURL):generateContent?key=\(apiKey)") else {
            throw GeminiServiceError.invalidURL
        }

        var generationConfig: [String: Any] = [
            "temperature": 1.0,
            "topP": 0.95,
            "topK": 40,
            "maxOutputTokens": 65536,
        ]
        if expectedMimeType == "application/json" {
            generationConfig["responseMimeType"] = "application/json"
        }

        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": generationConfig,
                //             "safetySettings": [
                //               {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                //               {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                //               {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                //               {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
                //             ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")  // Request to Gemini API is JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("Sending request to: \(url.absoluteString) with prompt: \(prompt.prefix(100))...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response object received.")
            throw GeminiServiceError.invalidResponse
        }

        let responseBodyString =
            String(data: data, encoding: .utf8) ?? "Could not decode response body"
        print(
            "--- Gemini API Full Response (Status: \(httpResponse.statusCode)) ---\n\(responseBodyString)\n---------------------------------"
        )

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorJson = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiServiceError.apiError(
                    "API Error \(httpResponse.statusCode): \(errorJson.error.message) (Status: \(errorJson.error.status), Code: \(errorJson.error.code))"
                )
            }
            throw GeminiServiceError.apiError(
                "Server returned error code \(httpResponse.statusCode). Response: \(responseBodyString.prefix(500))"
            )
        }

        do {
            let jsonResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
            guard let firstCandidate = jsonResponse.candidates?.first,
                let firstPart = firstCandidate.content?.parts.first,
                let textOutput = firstPart.text
            else {
                print("Could not find generated text in Gemini response structure.")
                throw GeminiServiceError.invalidResponse
            }
            return textOutput
        } catch let decodingError as DecodingError {
            print("Failed to parse Gemini API's own JSON response structure: \(decodingError)")
            print("Detailed DecodingError context: \(decodingError.localizedDescription)")
            // Provide more context for debugging
            switch decodingError {
            case let .typeMismatch(type, context):
                print(
                    "Type mismatch for \(type) in \(context.codingPath): \(context.debugDescription)"
                )
            case let .valueNotFound(type, context):
                print(
                    "Value not found for \(type) in \(context.codingPath): \(context.debugDescription)"
                )
            case let .keyNotFound(key, context):
                print("Key not found: \(key) in \(context.codingPath): \(context.debugDescription)")
            case let .dataCorrupted(context):
                print("Data corrupted in \(context.codingPath): \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error.")
            }
            throw GeminiServiceError.parsingError(
                "Failed to parse Gemini's main response structure: \(decodingError.localizedDescription)."
            )
        } catch {
            print("An unexpected error occurred while parsing Gemini's main response: \(error)")
            throw GeminiServiceError.parsingError(
                "Unexpected error parsing Gemini's main response: \(error.localizedDescription).")
        }
    }

    private struct GeminiDescriptionResponse: Codable {
        let description: String
    }

    func generateBookDescription(
        title: String, authors: [String], publisher: String?, publishedDateString: String?,
        categories: [String]?
    ) async throws -> String {
        var promptDetails = "Title: \(title)\\nAuthors: \(authors.joined(separator: ", "))"
        if let pub = publisher, !pub.isEmpty {
            promptDetails += "\\nPublisher: \(pub)"
        }
        if let dateStr = publishedDateString, !dateStr.isEmpty {
            promptDetails += "\\nPublished: \(dateStr)"  // Use the string directly
        }
        if let cats = categories, !cats.isEmpty {
            promptDetails += "\\nCategories/Genres: \(cats.joined(separator: ", "))"
        }

        let prompt = """
            You are an AI assistant. Based on the following book details, generate a concise and engaging book description (around 2-4 sentences, approximately 50-80 words).
            The description should sound like a blurb you might find on a book's back cover or an online bookstore.
            Focus on being enticing and giving a sense of the book's core.
            Avoid phrases like "This book is about...", "The description for this book is...", or "Based on the details provided...". Just provide the description itself.

            Book Details:
            \(promptDetails)

            Your entire response MUST be a valid JSON object with a single key "description" whose value is the generated description string.
            The description string itself should not contain complex markdown, but simple newlines (\\n) are acceptable if natural for a blurb.

            Example of your JSON output:
            {
                "description": "In a realm fractured by ancient magic, a reluctant hero must embrace a forgotten destiny. Faced with shadowy adversaries and perilous quests, their journey will determine the fate of worlds. A tale of courage, sacrifice, and the enduring power of hope."
            }
            Do NOT include any text, explanations, or markdown formatting outside of the JSON object itself.
            """

        let rawJsonResponseString = try await sendRequest(
            prompt: prompt, expectedMimeType: "application/json")
        print(
            "--- Raw response for BookDescription ---\n\(rawJsonResponseString)\n---------------------------------"
        )
        let cleanedJsonResponseString = cleanJsonResponseString(rawJsonResponseString)
        print(
            "--- Cleaned response for BookDescription ---\n\(cleanedJsonResponseString)\n---------------------------------"
        )

        do {
            let decoder = JSONDecoder()
            guard let jsonData = cleanedJsonResponseString.data(using: .utf8) else {
                print(
                    "Error converting cleaned JSON string to Data for BookDescription. Cleaned string was: '\(cleanedJsonResponseString)'"
                )
                throw GeminiServiceError.invalidData
            }
            let response = try decoder.decode(GeminiDescriptionResponse.self, from: jsonData)
            return response.description
        } catch {
            print("Parsing error for BookDescription. Original error: \(error)")
            print("Problematic JSON string for BookDescription was: '\(cleanedJsonResponseString)'")
            // Fallback: if the response is plain text and looks plausible as a description, use it.
            if !cleanedJsonResponseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(
                "{")
                && !cleanedJsonResponseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                && cleanedJsonResponseString.count > 20
            {  // Arbitrary length to guess it's a description
                print(
                    "BookDescription response was not JSON, returning cleaned text directly as a fallback description."
                )
                return cleanedJsonResponseString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            throw GeminiServiceError.parsingError(
                "Failed to parse book description JSON response: \(error.localizedDescription)")
        }
    }

    func fallbackSubChoices(for primaryMood: String) -> [MoodChoice] {
        switch primaryMood {
        case "Uplifting":
            return [
                MoodChoice(name: "Heartwarming Story", icon: "heart.fill"),
                MoodChoice(name: "Funny & Light", icon: "face.smiling.fill"),
                MoodChoice(name: "Inspiring Tale", icon: "star.fill"),
            ]
        case "Intriguing":
            return [
                MoodChoice(name: "Page-Turner Mystery", icon: "magnifyingglass"),
                MoodChoice(name: "Mind-Bending Plot", icon: "brain.head.profile"),
                MoodChoice(name: "Historical Secret", icon: "scroll.fill"),
            ]
        default:
            return [
                MoodChoice(name: "Popular Now", icon: "flame.fill"),
                MoodChoice(name: "Award-Winning", icon: "trophy.fill"),
                MoodChoice(name: "Hidden Gem", icon: "sparkles"),
            ]
        }
    }

    func fallbackBookSuggestions(for primaryMood: String, subChoice: String) -> [BookSuggestion] {
        return [
            BookSuggestion(
                title: "The Midnight Library (Fallback)",
                author: "Matt Haig",
                reason:
                    "A thought-provoking journey about life's choices, fitting a \(primaryMood.lowercased()) mood seeking \(subChoice.lowercased())."
            ),
            BookSuggestion(
                title: "Project Hail Mary (Fallback)",
                author: "Andy Weir",
                reason:
                    "An exciting space adventure for your \(primaryMood.lowercased()) desire for \(subChoice.lowercased())."
            ),
            BookSuggestion(
                title: "The House in the Cerulean Sea (Fallback)",
                author: "T.J. Klune",
                reason:
                    "A heartwarming tale of found family, bringing \(primaryMood.lowercased()) energy via its \(subChoice.lowercased()) theme."
            ),
        ]
    }
}

// MARK: - Book Club Insights
struct BookClubInsights: Codable {
    let discussionQuestions: [String]
    let themes: [String]
    let interestingFacts: [String]
}