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
    
    // Sample books data
    @State private var requestedBooks: [BookModel] = []
    @State private var wishlistBooks: [BookModel] = []
    @State private var borrows: [BorrowModel] = []
    private var currentBooks:[BookModel]{
        let filtered = borrows.filter{$0.status == .borrowed}
        return filtered.compactMap(\.book)
    }
    private var returnedBooks:[BookModel]{
        let filtered = borrows.filter{$0.status == .returned}
        return filtered.compactMap(\.book)
    }


    @State private var demoBooks: [BookModel] = [
        BookModel(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            title: "The Swift Programming Language",
            isbn: "9781491949863",
            description: "An in-depth guide to the Swift language by Apple.",
            totalCopies: 10,
            availableCopies: 7,
            reservedCopies: 1,
            authorIds: [UUID(uuidString: "aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
            authorNames: ["Apple Inc."],
            genreIds: [UUID(uuidString: "bbbb1111-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
            publishedDate: ISO8601DateFormatter().date(from: "2019-06-04T00:00:00Z"),
            addedOn: ISO8601DateFormatter().date(from: "2025-04-20T12:00:00Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2025-04-25T10:00:00Z"),
            coverImageUrl: "https://images.apple.com/books/images/swift-book-cover-large.jpg",
            coverImageData: nil
        ),
        BookModel(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            title: "SwiftUI Essentials",
            isbn: "9781950325022",
            description: "Learn how to build beautiful and modern UIs using SwiftUI.",
            totalCopies: 8,
            availableCopies: 5,
            reservedCopies: 2,
            authorIds: [UUID(uuidString: "aaaa2222-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
            authorNames: ["Chris Eidhof"],
            genreIds: [UUID(uuidString: "bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
            publishedDate: ISO8601DateFormatter().date(from: "2022-10-15T00:00:00Z"),
            addedOn: ISO8601DateFormatter().date(from: "2025-04-21T09:30:00Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2025-04-25T10:00:00Z"),
            coverImageUrl: "https://images.apple.com/books/images/swift-book-cover-large.jpg",
            coverImageData: nil
        )
    ]
    private var finalBooks: [BookModel] {
        switch(selectedTab){
        case .request:
            return requestedBooks
        case .wishlist:
            return wishlistBooks
        case .current:
            return currentBooks
        case .returned:
            return returnedBooks
        }
    }
    
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
                tabBarView
                
                // MARK: - Book Collection Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        // Filter books based on the selected tab
                        ForEach(finalBooks.prefix(6)) { book in
                            BookCardView(book: book, tab: selectedTab, colorScheme: colorScheme)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                Spacer()
            }
        }
        .onAppear(){
            Task{
                borrows = try await BorrowHandler.shared.getBorrows()
            }
        }
        .onAppear(){
            Task{

                self.wishlistBooks = try await getWishList()
            }
        }
        .onAppear(){
            Task{
                let reservations = try await ReservationHandler.shared.getReservations()
                //get books from borrows
                requestedBooks = reservations.compactMap(\.book)
            }
        }
        .background(ReusableBackground(colorScheme: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Tab Bar View
    private var tabBarView: some View {
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
        .padding(.horizontal)
    }
}

// MARK: - Book Card Component

struct BookCardView: View {
    
    let book: BookModel
    let tab: BookCollectionTab
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Image Container
            ZStack(alignment: .topTrailing) {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                }else{
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
            }
            .onAppear(){
                loadCoverImage()
            }
            
            // Book Title
            Text(book.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.text(for: colorScheme))
                .lineLimit(1)
            
            // Author Name
            Text(book.authorNames?.first ?? "Unknown Author")
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
    private func loadCoverImage() {
        // Set loading state
        isLoading = true
        
        // First try to load from local data
        if let imageData = book.coverImageData {
            loadedImage = UIImage(data: imageData)
            isLoading = false
            return
        }
        
        // If no local data, try to load from URL
        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(
                of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    loadError = true
                    return
                }
                
                loadedImage = image
            }
        }.resume()
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
