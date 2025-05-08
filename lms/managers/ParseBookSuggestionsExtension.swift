import Foundation
// Assuming GeminiService class and BookSuggestion struct are defined elsewhere
// and BookSuggestion has an init(title: String, author: String?, reason: String)

extension FolioService {
    // Parse book suggestions using regex when JSON is malformed
    // This is a fallback mechanism.
    internal func parseBookSuggestionsWithRegex(_ jsonString: String) -> [BookSuggestion] { // Made internal for access within module
        print("Attempting specialized regex fix for book suggestions JSON (with author)")
        var fixedArray: [BookSuggestion] = []
        
        // Pattern to find "title": "...", "author": "...", "reason": "..."
        // This pattern assumes this order of fields within each "object".
        // It captures the values inside the quotes.
        // It's designed to be somewhat resilient to extra whitespace \s*
        // and the comma , separating the fields.
        let pattern = #""title"\s*:\s*"([^"]*)"\s*,\s*"author"\s*:\s*"([^"]*)"\s*,\s*"reason"\s*:\s*"([^"]*)""#

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = jsonString as NSString
            let matches = regex.matches(in: jsonString, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                // We expect 4 ranges:
                // 0: The full matched string (e.g., "title": "A", "author": "B", "reason": "C")
                // 1: Content of title
                // 2: Content of author
                // 3: Content of reason
                if match.numberOfRanges >= 4 {
                    let title = nsString.substring(with: match.range(at: 1))
                    let author = nsString.substring(with: match.range(at: 2))
                    let reason = nsString.substring(with: match.range(at: 3))
                    
                    // Basic validation: ensure captured strings are not empty if that's a requirement
                    // For now, we'll assume any captured string is valid.
                    fixedArray.append(BookSuggestion(title: title, author: author, reason: reason))
                }
            }
        }
        
        if !fixedArray.isEmpty {
            print("Regex extracted \(fixedArray.count) book suggestions.")
        } else {
            // Print a snippet of the string to help debug if regex fails
            let snippetLength = min(jsonString.count, 300)
            let snippet = String(jsonString.prefix(snippetLength))
            print("Regex found no book suggestions in the provided string. Snippet: '\(snippet)...'")
        }
        return fixedArray
    }
}
