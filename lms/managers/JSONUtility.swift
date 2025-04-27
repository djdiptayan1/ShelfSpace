//
//  JSONUtility.swift
//  lms
//
//  Created by Diptayan Jash on 27/04/25.
//

import Foundation
import SwiftUI

/// A utility class for handling JSON encoding and decoding operations throughout the app
class JSONUtility {
    // MARK: - Shared Instance
    static let shared = JSONUtility()
    
    // MARK: - Properties
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    private init() {
        // Setup encoder with standard configuration
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Setup decoder with standard configuration
        decoder = JSONDecoder()
        
        // Custom date decoding strategy that tries multiple formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try formats in order of preference
            let formatters: [DateFormatter] = [
                // ISO8601 with fractional seconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }(),
                // ISO8601 without fractional seconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }(),
                // Simple date format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }()
            ]
            
            // Try ISO8601DateFormatter first (handles most standard cases)
            let iso8601WithFractional = ISO8601DateFormatter()
            iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = iso8601WithFractional.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without fractional seconds
            let iso8601 = ISO8601DateFormatter()
            iso8601.formatOptions = [.withInternetDateTime]
            
            if let date = iso8601.date(from: dateString) {
                return date
            }
            
            // Try other formatters
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
    }
    
    // MARK: - Encoding Functions
    
    /// Encode an object to JSON Data
    /// - Parameter value: The value to encode
    /// - Returns: Encoded JSON data
    /// - Throws: Encoding errors
    func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            let data = try encoder.encode(value)
            return data
        } catch {
            print("🔴 JSON Encoding Error: \(error)")
            throw error
        }
    }
    
    /// Encode an object and return it as a JSON string
    /// - Parameter value: The value to encode
    /// - Returns: JSON string representation
    /// - Throws: Encoding errors
    func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "JSONUtility", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string"])
        }
        return jsonString
    }
    
    // MARK: - Decoding Functions
    
    /// Decode JSON data into an object
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - data: The JSON data
    /// - Returns: Decoded object
    /// - Throws: Decoding errors
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let result = try decoder.decode(type, from: data)
            return result
        } catch {
            print("🔴 JSON Decoding Error: \(error)")
            
            // Additional helpful debugging for decoding errors
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found: \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
                
                // Print a preview of the data
                if let jsonString = String(data: data, encoding: .utf8) {
                    let preview = String(jsonString.prefix(200)) + (jsonString.count > 200 ? "..." : "")
                    print("JSON data preview: \(preview)")
                }
            }
            
            throw error
        }
    }
    
    /// Decode a JSON string into an object
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - string: The JSON string
    /// - Returns: Decoded object
    /// - Throws: Decoding errors
    func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "JSONUtility", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        return try decode(type, from: data)
    }
    
    // MARK: - Useful Helper Methods
    
    /// Convert any dictionary to JSON data
    /// - Parameter dictionary: The dictionary to convert
    /// - Returns: JSON data
    /// - Throws: Encoding errors
    func encodeFromDictionary(_ dictionary: [String: Any]) throws -> Data {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
            return data
        } catch {
            print("🔴 Dictionary to JSON Error: \(error)")
            throw error
        }
    }
    
    /// Convert JSON data to a dictionary
    /// - Parameter data: The JSON data
    /// - Returns: Dictionary representation
    /// - Throws: Decoding errors
    func decodeToDictionary(from data: Data) throws -> [String: Any] {
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NSError(domain: "JSONUtility", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to dictionary"])
            }
            return dictionary
        } catch {
            print("🔴 JSON to Dictionary Error: \(error)")
            throw error
        }
    }
    
    /// Create a custom decoder with specific settings
    /// - Parameter keyDecodingStrategy: The key decoding strategy (default is .useDefaultKeys)
    /// - Returns: A configured JSONDecoder
    func customDecoder(keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> JSONDecoder {
        let customDecoder = JSONDecoder()
        customDecoder.dateDecodingStrategy = decoder.dateDecodingStrategy
        customDecoder.keyDecodingStrategy = keyDecodingStrategy
        return customDecoder
    }
    
    /// Create a custom encoder with specific settings
    /// - Parameter keyEncodingStrategy: The key encoding strategy (default is .useDefaultKeys)
    /// - Returns: A configured JSONEncoder
    func customEncoder(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) -> JSONEncoder {
        let customEncoder = JSONEncoder()
        customEncoder.dateEncodingStrategy = encoder.dateEncodingStrategy
        customEncoder.outputFormatting = encoder.outputFormatting
        customEncoder.keyEncodingStrategy = keyEncodingStrategy
        return customEncoder
    }
}

// MARK: - Easy-to-use global functions

/// Encode an object to JSON data using the shared utility
/// - Parameter value: The value to encode
/// - Returns: Encoded JSON data
/// - Throws: Encoding errors
func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
    return try JSONUtility.shared.encode(value)
}

/// Decode JSON data into an object using the shared utility
/// - Parameters:
///   - type: The type to decode to
///   - data: The JSON data
/// - Returns: Decoded object
/// - Throws: Decoding errors
func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    return try JSONUtility.shared.decode(type, from: data)
}

// MARK: - Error Extension

/// Extension to make API errors more informative
extension Error {
    /// Get a user-friendly description of the error
    var friendlyDescription: String {
        if let decodingError = self as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, _):
                return "Missing field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                return "Incorrect data type: Expected \(type)"
            case .valueNotFound(let type, _):
                return "Missing value for type: \(type)"
            case .dataCorrupted(let context):
                return "Data format error: \(context.debugDescription)"
            @unknown default:
                return "Unknown JSON decoding error"
            }
        } else {
            return localizedDescription
        }
    }
    
    /// Log detailed error information
    func logDetails() {
        print("🔴 Error: \(self)")
        
        if let decodingError = self as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("- Key not found: \(key.stringValue)")
                print("- Context: \(context.debugDescription)")
                print("- Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
            case .typeMismatch(let type, let context):
                print("- Type mismatch: expected \(type)")
                print("- Context: \(context.debugDescription)")
                print("- Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
            case .valueNotFound(let type, let context):
                print("- Value not found: \(type)")
                print("- Context: \(context.debugDescription)")
                print("- Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
            case .dataCorrupted(let context):
                print("- Data corrupted: \(context.debugDescription)")
                print("- Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
            @unknown default:
                print("- Unknown decoding error")
            }
        }
    }
}
