//
//  genreModel.swift
//  lms
//
//  Created by Diptayan Jash on 30/04/25.
//

import Foundation
import SwiftUI

/// Represents book genres available in the application
enum BookGenre: String, CaseIterable, Identifiable, Hashable {
    // Fiction categories
    case all = "All"
    case fiction = "Fiction"
    case mystery = "Mystery"
    case thriller = "Thriller"
    case romance = "Romance"
    case scienceFiction = "Science Fiction"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case contemporary = "Contemporary"
    case classics = "Classics"
    case youngAdult = "Young Adult"
    case adventure = "Adventure"
    case crime = "Crime"
    case dystopian = "Dystopian"
    case historicalFiction = "Historical Fiction"
    
    // Non-fiction categories
    case nonFiction = "Non-Fiction"
    case biography = "Biography"
    case history = "History"
    case selfHelp = "Self-Help"
    case business = "Business"
    case poetry = "Poetry"
    
    // MARK: - Identifiable conformance
    var id: String { rawValue }
    
    // MARK: - Helper properties
    
    /// Returns all fiction genres
    static var fictionGenres: [BookGenre] {
        return [.fiction, .mystery, .thriller, .romance, .scienceFiction,
                .fantasy, .horror, .contemporary, .classics, .youngAdult,
                .adventure, .crime, .dystopian, .historicalFiction]
    }
    
    /// Returns all non-fiction genres
    static var nonFictionGenres: [BookGenre] {
        return [.nonFiction, .biography, .history, .selfHelp, .business, .poetry]
    }
    
    /// Returns the display name for the genre
    var displayName: String {
        return rawValue
    }
    
    /// Returns a color associated with the genre (for UI customization)
    var themeColor: Color {
        switch self {
        case .fiction, .contemporary, .classics:
            return .blue
        case .mystery, .crime, .thriller:
            return .purple
        case .romance:
            return .pink
        case .scienceFiction, .dystopian:
            return .cyan
        case .fantasy, .adventure:
            return .green
        case .horror:
            return .red
        case .youngAdult:
            return .orange
        case .historicalFiction, .history:
            return .brown
        case .nonFiction, .biography, .business:
            return .gray
        case .selfHelp:
            return .yellow
        case .poetry:
            return .indigo
        case .all:
            return .blue
        }
    }
    
    /// Returns a system icon name associated with the genre
    var iconName: String {
        switch self {
        case .fiction:
            return "book"
        case .mystery, .crime:
            return "magnifyingglass"
        case .thriller:
            return "bolt"
        case .romance:
            return "heart"
        case .scienceFiction:
            return "star"
        case .fantasy:
            return "wand.and.stars"
        case .horror:
            return "theatermasks"
        case .contemporary:
            return "person.2"
        case .classics:
            return "clock"
        case .youngAdult:
            return "person"
        case .adventure:
            return "map"
        case .dystopian:
            return "building.2"
        case .historicalFiction, .history:
            return "scroll"
        case .nonFiction:
            return "doc.text"
        case .biography:
            return "person.text.rectangle"
        case .selfHelp:
            return "hand.raised"
        case .business:
            return "briefcase"
        case .poetry:
            return "text.quote"
        case .all:
            return "book"
        }
    }
    
    /// Returns a description for each genre
    var description: String {
        switch self {
        case .fiction:
            return "Imaginative stories not presented as fact"
        case .mystery:
            return "Stories involving a puzzle or crime to be solved"
        case .thriller:
            return "Fast-paced, suspenseful stories filled with tension"
        case .romance:
            return "Stories centered on relationships and romantic love"
        case .scienceFiction:
            return "Stories based on imagined future scientific advances"
        case .fantasy:
            return "Stories set in magical or supernatural worlds"
        case .horror:
            return "Stories designed to frighten or unsettle"
        case .contemporary:
            return "Fiction set in the present time"
        case .classics:
            return "Works notable for literary merit and cultural significance"
        case .youngAdult:
            return "Fiction written for readers aged 12-18"
        case .adventure:
            return "Stories of exciting journeys and challenges"
        case .crime:
            return "Stories centered on criminal acts and their investigation"
        case .dystopian:
            return "Fiction depicting a society marked by oppression"
        case .historicalFiction:
            return "Fiction set in the past with historical context"
        case .nonFiction:
            return "Factual works based on real events or information"
        case .biography:
            return "Accounts of a person's life written by another"
        case .history:
            return "Study of past events and human affairs"
        case .selfHelp:
            return "Books aimed at personal improvement"
        case .business:
            return "Books about commerce, management, and economics"
        case .poetry:
            return "Literary work expressing ideas through rhythm and imagery"
        case .all:
            return "all genres"
        }
    }
}

// MARK: - Extensions for UI handling
extension BookGenre {
    /// Returns genre button style for the given selection state and color scheme
    func buttonStyle(isSelected: Bool, colorScheme: ColorScheme) -> some View {
        Text(displayName)
            .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : Color.text(for: colorScheme))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.secondary(for: colorScheme) : Color.background(for: colorScheme))
                    .shadow(color: Color.primary(for: colorScheme).opacity(isSelected ? 0.2 : 0.08),
                            radius: isSelected ? 6 : 4,
                            x: 0,
                            y: isSelected ? 3 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.clear : Color.text(for: colorScheme).opacity(0.1),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}
