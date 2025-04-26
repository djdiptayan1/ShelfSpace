//
//  BookCollectionuser.swift
//  lms
//
//  Created by Navdeep Lakhlan on 25/04/25.
//
import SwiftUI

// MARK: - Enums

/// Tab options for the book collection view
enum BookCollectionTab: String, CaseIterable {
    case wishlist = "Wishlist"
    case current = "Current"
    case returned = "Returned"
    case request = "Requests"
    
    /// System icon name for each tab
    var icon: String {
        switch self {
        case .wishlist:
            return "heart"
        case .current:
            return "book"
        case .returned:
            return "arrow.uturn.backward"
        case .request:
            return "arrow.right.square"
        }
    }
}

// MARK: - Main View

struct BookCollectionuser: View {
    // MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @State private var selectedTab: BookCollectionTab = .request
    @State private var expandedTab: Bool = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            ReusableBackground(colorScheme: colorScheme)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Collections Title
                Text("Collections")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // MARK: - Tab Bar (Apple Mail-style)
                HStack(spacing: 14) {
                    ForEach(BookCollectionTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring()) {
                                if selectedTab == tab {
                                    // Toggle expansion when tapping the selected tab
                                    expandedTab.toggle()
                                } else {
                                    selectedTab = tab
                                    expandedTab = true
                                }
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: tab.icon)
                                    .font(.headline)
                                
                                if expandedTab && selectedTab == tab {
                                    Text(tab.rawValue)
                                        .font(.system(size: 13))
                                        .transition(.opacity)
                                }
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal, 18)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        Capsule()
                                            .fill(Color.primary(for: colorScheme).opacity(0.6))
                                            .matchedGeometryEffect(id: "TAB", in: animation)
                                            
                                    }
                                }
                            )
                            .foregroundColor(selectedTab == tab ? .white : Color.text(for: colorScheme).opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Color.TabbarBackground(for: colorScheme).opacity(0.7))
//                        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.2),
//                                radius: 4, x: 0, y: 2)
//                )
                .padding(.horizontal)
                
                // MARK: - Book Collection Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        // Filter books based on the selected tab
                        ForEach(demoBooks.prefix(6)) { book in
                            BookCardView(book: book, tab: selectedTab, colorScheme: colorScheme)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                Spacer()
            }
        }
        .background(ReusableBackground(colorScheme: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Book Card Component

struct BookCardView: View {
    
    let book: BookModel
    let tab: BookCollectionTab
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Image Container
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius:10)
                    .fill(Color.TabbarBackground(for: colorScheme))
                    .frame(height: 200)
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.3),
                            radius: 5, x: 0, y: 3)
                    .overlay(
                        Text("BOOK IMAGE")
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.5))
                            .font(.caption2)
                    )
                
                // Bookmark Button
//                Button(action: {}) {
//                    Image(systemName: "bookmark.fill")
//                        .foregroundColor(Color.primary(for: colorScheme))
//                        .padding(8)
//                        .background(Color.TabbarBackground(for: colorScheme))
//                        .clipShape(Circle())
//                        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.3),
//                                radius: 2, x: 0, y: 1)
//                        .padding(8)
//                }
            }
            
            // Book Title
            Text(book.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.text(for: colorScheme))
                .lineLimit(1)
            
            // Author Name
            Text(book.authorNames.first ?? "")
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            // Due Date Information (conditional based on tab)
            if tab == .current || tab == .request {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color.secondary(for: colorScheme))
                    Text("Due: 12th Jun")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else if tab == .wishlist || tab == .returned {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color.secondary(for: colorScheme))
                    Text("Available till: 12th Jun")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Status Tags
            HStack(spacing: 6) {
                Text(tab.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary(for: colorScheme).opacity(0.7))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                
                if tab == .current {
                    Text("Overdue")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.TabbarBackground(for: colorScheme).opacity(0.8))
        .cornerRadius(10)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.2),
                radius: 6, x: 0, y: 3)
    }
}

// MARK: - Preview

struct bookCollectionuser_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BookCollectionuser()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            BookCollectionuser()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
