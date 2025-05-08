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
    case wishlist = "Bookmarked"
    case current = "Current"
    case returned = "Returned"
    case request = "Requests"
    
    /// System icon name for each tab
    var icon: String {
        switch self {
        case .wishlist:
            return "bookmark"
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
    @Environment(\.presentationMode) var presentationMode
    @Namespace private var animation
    @State private var selectedTab: BookCollectionTab = .request
    @State private var expandedTab: Bool = true
    
    // Sample books data
    @State private var requestedBooks: [BookModel] = []
    @State private var wishlistBooks: [BookModel] = []
    @State private var borrows: [BorrowModel] = []
    @State private var reservations:[ReservationModel] = []
    @State private var currentBooks:[BookModel] = []
    @State private var returnedBooks:[BookModel] = []
    @State private var policy:Policy?


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
        NavigationView {
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
                                NavigationLink(destination: BookDetailView(book: book))
                                {
                                    BookCardView(book: book, tab: selectedTab, colorScheme: colorScheme,reservation: $reservations,borrows: $borrows,policy: $policy)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    Spacer()
                }
            }
            .onAppear(){
                fetchPolicy(libraryId: UUID()) { policy in
                    self.policy = policy
                }
            }
            .onAppear {
                        Task {
                            await loadBookData()
                        }
                    }
            .onAppear(){
                Task{
                    self.wishlistBooks = try await getWishList()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width > 100 {
                            // Swipe from left to right (standard iOS back gesture)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
            )
        }
    }
    func loadBookData() async {
            do {
                async let borrowsData = BorrowHandler.shared.getBorrows()
                async let reservationsData = ReservationHandler.shared.getReservations()

                self.borrows = try await borrowsData
                self.reservations = try await reservationsData

                let currentFilteredBorrows = borrows.filter { $0.status == .borrowed }
                let returnedFilteredBorrows = borrows.filter { $0.status == .returned }

                let borrowCurrentBookIds = Set(currentFilteredBorrows.compactMap(\.book_id))
                let borrowReturnedBookIds = Set(returnedFilteredBorrows.compactMap(\.book_id))
                let reservationBookIds = Set(reservations.compactMap(\.book_id))

                var allUniqueBookIds = Set<UUID>()
                allUniqueBookIds.formUnion(borrowCurrentBookIds)
                allUniqueBookIds.formUnion(borrowReturnedBookIds)
                allUniqueBookIds.formUnion(reservationBookIds)

                if allUniqueBookIds.isEmpty {
                    print("ℹ️ No book IDs to process from borrows or reservations.")
                    currentBooks = []
                    returnedBooks = []
                    requestedBooks = []
                    return
                }

                print("ℹ️ All unique book IDs to resolve: \(allUniqueBookIds.map { $0.uuidString }.joined(separator: ", "))")

                var resolvedBooks: [UUID: BookModel] = [:]

                if let cachedBooksArray = BookHandler.shared.getCachedData() {
                    for book in cachedBooksArray {
                        if allUniqueBookIds.contains(book.id) {
                            resolvedBooks[book.id] = book
                            print("✅ Found book \(book.id) in cache: \(book.title)")
                        }
                    }
                }

                let missingBookIds = allUniqueBookIds.filter { resolvedBooks[$0] == nil }

                if !missingBookIds.isEmpty {
                    print("ℹ️ Missing \(missingBookIds.count) books from cache. Fetching them: \(missingBookIds.map { $0.uuidString }.joined(separator: ", "))")
                    var newlyFetchedBooks: [BookModel] = []

                    try await withThrowingTaskGroup(of: BookModel?.self) { group in
                        for bookId in missingBookIds {
                            group.addTask {
                                print("🚀 Fetching book with ID: \(bookId)")
                                return try await fetchBookFromId(bookId)
                            }
                        }

                        for try await fetchedBook in group {
                            if let book = fetchedBook {
                                newlyFetchedBooks.append(book)
                                resolvedBooks[book.id] = book
                            }
                        }
                    }
                    
                } else {
                    print("✅ All required books were found in the cache.")
                }

                currentBooks = borrowCurrentBookIds.compactMap { resolvedBooks[$0] }
                returnedBooks = borrowReturnedBookIds.compactMap { resolvedBooks[$0] }
                requestedBooks = reservationBookIds.compactMap { resolvedBooks[$0] }

                print("✅ Successfully loaded book data. Current: \(currentBooks.count), Returned: \(returnedBooks.count), Requested: \(requestedBooks.count)")

            } catch {
                print("❌ Error in loadBookData: \(error.localizedDescription)")
                error.logDetails() // Make sure this extension is available
            }
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
                                .font(.system(size: 12))
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 15)
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
    private var dueDate:Date?{
        if let res = reservation.first(where: { $0.book_id == book.id }),tab == .request{
            return res.expires_at
        }
        if tab == .current, let borrow = borrows.first(where: { $0.book_id == book.id }){
                if let days = policy?.max_borrow_days {
                    let newDate = Calendar.current.date(byAdding: .day, value: days, to: borrow.borrow_date)
                    return newDate
            }
        }
        return nil
    }
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    @Binding var reservation:[ReservationModel]
    @Binding var borrows:[BorrowModel]
    @Binding var policy:Policy?
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Book Image Container
            ZStack(alignment: .top) {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 134,height: 200)
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
                }
            }
            .onAppear(){
                loadCoverImage()
            }
            // Book Title - limited to 3 lines
            Text(book.title)
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(Color.text(for: colorScheme))
                .lineLimit(3)
                .frame(height:60, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            
            // Author Name
            Text((book.authorNames?.isEmpty ?? true ? "" : book.authorNames?[0]) ?? "")
                .font(.system(size:12))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            // Due Date Information (conditional based on tab)
            if tab == .current || tab == .request {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color.secondary(for: colorScheme))
                    if dueDate != nil{
                        Text("Due: \(dueDate!.shortFormatted)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Status Tags
            HStack(spacing: 6) {
                if tab == .current, dueDate != nil, dueDate! < Date() {
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
extension Date {
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }
}
