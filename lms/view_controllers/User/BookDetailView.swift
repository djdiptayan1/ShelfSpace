import Combine
import Foundation
import SwiftUI
import UIKit

struct BookDetailView: View {
    @State var book: BookModel
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    // State to track book status (you might want to move this to your Book model)
    @State private var bookStatus: BookStatus = .loading
    // Add rating state
    @State private var userRating: Int = 0

    // Add bookmark state
    @State private var isBookmarked: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    // Add tab selection state
    @State private var selectedTab: TabSection = .details

    enum TabSection: String, CaseIterable {
        case details = "Description"
        case reviews = "Reviews"
        case bookClub = "Book Club"
    }
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    @State private var user: User?

    @State private var isBorrowLoading: Bool = false
    @State private var borrow: BorrowModel?
    @State private var reservation: ReservationModel?
    @State private var isBorrowed = false
    @State private var isReserved = false

    // Book Club insights
    @State private var bookClubQuestions: [String] = []
    @State private var bookClubThemes: [String] = []
    @State private var bookClubFacts: [String] = []
    @State private var isLoadingBookClubInsights: Bool = false
    @State private var bookClubError: String? = nil

    var body: some View {

        ZStack(alignment: .top) {
            // Using the reusable background instead of hard-coded color
            ReusableBackground(colorScheme: colorScheme)

            VStack(spacing: 0) {
                // Fixed header with back button, title, and bookmark
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color.text(for: colorScheme))
                    }
                    .accessibility(label: Text("Back"))
                    .accessibility(hint: Text("Double tap to go back to previous screen"))

                    Spacer()

                    // Navigation title
                    Text("Book Details")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.text(for: colorScheme))
                        .accessibility(addTraits: .isHeader)

                    Spacer()

                    // Bookmark button moved to navigation bar
                    Button(action: {
                        Task {
                            if !isBookmarked {
                                isBookmarked.toggle()
                                LoginManager.shared.addToWishlist(bookId: book.id)
                                do {
                                    try await addToWishlistAPI(bookId: book.id)
                                } catch {
                                    LoginManager.shared.removeFromWishlist(bookId: book.id)
                                }
                            } else {
                                LoginManager.shared.removeFromWishlist(bookId: book.id)
                                isBookmarked.toggle()
                                do {
                                    try await removeWishListApi(bookId: book.id)
                                } catch {
                                    LoginManager.shared.addToWishlist(bookId: book.id)
                                }
                            }
                        }
                    }) {
                        Image(
                            systemName: isBookmarked
                                ? "bookmark.fill" : "bookmark"
                        )
                        .font(.system(size: 22))
                        .foregroundColor(
                            isBookmarked
                                ? Color.primary(for: colorScheme).opacity(0.6)
                                : Color.primary(for: colorScheme).opacity(0.6))
                    }
                    .accessibility(
                        label: Text(isBookmarked ? "Remove from bookmarks" : "Add to bookmarks")
                    )
                    .accessibility(hint: Text("Double tap to toggle bookmark status"))
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Book cover and details layout similar to the provided image
                        HStack(alignment: .top, spacing: 20) {
                            // Book Cover Image
                            if let image = loadedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 170, height: 240)
                                    .shadow(
                                        color: Color.black.opacity(0.2),
                                        radius: 5, x: 0, y: 3
                                    )
                                    .clipped()
                                    .padding(.leading)
                                    .accessibility(hidden: true)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "A1C4FD"),
                                                Color(hex: "C2E9FB"),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .accessibility(hidden: true)

                                Image(systemName: "book.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.7))
                                    .accessibility(hidden: true)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                // Title in larger font like the image
                                Text(book.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .padding(.top, 5)
                                    .accessibility(addTraits: .isHeader)

                                // Author with "by" prefix as shown in the image
                                Text(
                                    "by " + (book.authorNames!.isEmpty ? "" : book.authorNames![0])
                                )
                                .font(.system(size: 18))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                            }
                            .padding(.trailing)

                        }
                        // Status badge - made to look like the blue button in the image
                        Text(bookStatus.displayText)
                            .font(.system(size: 20).bold())
                            .foregroundColor(Color.secondary(for: colorScheme))
                            .padding(.leading, 16)
                            .accessibility(label: Text("Book status: \(bookStatus.displayText)"))

                        // Genre tags in a horizontal scroll - styling similar to the teal buttons in the image
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(book.genreNames ?? [], id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 14).bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                        .background(
                                            Color.gray.opacity(0.15)
                                        )
                                        .foregroundColor(Color.text(for: colorScheme))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibility(
                            label: Text("Genres: \(book.genreNames?.joined(separator: ", ") ?? "")")
                        )

                        // Tab selector for Details and Reviews
                        HStack(spacing: 0) {
                            ForEach(TabSection.allCases, id: \.self) { tab in
                                Button(action: {
                                    selectedTab = tab
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab.rawValue)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: selectedTab == tab
                                                        ? .bold : .medium)
                                            )
                                            .foregroundColor(
                                                selectedTab == tab
                                                    ? Color.text(for: colorScheme) : .gray)

                                        // Indicator line
                                        Rectangle()
                                            .frame(height: 3)
                                            .foregroundColor(
                                                selectedTab == tab
                                                    ? .blue : .clear)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .accessibility(label: Text(tab.rawValue))
                                .accessibility(
                                    addTraits: selectedTab == tab
                                        ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .padding(.horizontal)
                        .accessibilityElement(children: .contain)
                        .accessibility(label: Text("Tabs"))
                        .accessibility(hint: Text("Swipe left or right to navigate between tabs"))

                        // Content based on selected tab
                        switch selectedTab {
                        case .details:
                            detailsSection
                        case .reviews:
                            reviewsSectionContent()
                        case .bookClub:
                            bookClubSection
                        }
                    }
                    .padding(.vertical)
                }
            }
            .onAppear {
                loadCoverImage()
            }
            .onAppear {
                Task {
                    let wishlist = try await getWishList()
                    isBookmarked = wishlist.contains(where: { $0.id == book.id })
                }
            }
            .onAppear {
                BookHandler.shared.socketHandler.messagePublisher
                    .receive(on: DispatchQueue.global(qos: .default))
                    .sink { message in
                        print(message.type)
                        if message.type == "bookUpdated", message.data.id == book.id {
                            book = message.data
                        }
                    }.store(in: &cancellables)
            }
            .onAppear {
                Task {
                    self.isBorrowLoading = true
                    user = try await LoginManager.shared.getCurrentUser()
                    let borrow = try await BorrowHandler.shared.getBorrowForBookId(book.id)
                    let reserved = try await ReservationHandler.shared.getReservationForBookId(
                        book.id)
                    isLoading = false
                    isBorrowLoading = false
                    if reserved != nil {
                        bookStatus = .requested
                        return
                    }
                    if borrow != nil {
                        if borrow!.status == .borrowed {
                            bookStatus = .reading
                            return
                        } else {
                            bookStatus = .completed(dueDate: Date())
                            return
                        }
                    }
                    if book.availableCopies == 0 {
                        bookStatus = .notAvailable
                    } else {
                        bookStatus = .available

                    }
                }
            }
            .navigationBarHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibility(label: Text("Book details for \(book.title)"))
    }

    // Rest of the code remains the same...
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

        print("Loading image from URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Always reset loading state when completed
            DispatchQueue.main.async {
                isLoading = false
            }

            // Check for errors
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for success status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid image data
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Update UI with loaded image
            DispatchQueue.main.async {
                print("Image loaded successfully")
                loadedImage = image
            }
        }.resume()
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cards section
            Divider()
                .padding(.horizontal)

            // Description
            VStack(alignment: .leading, spacing: 10) {

                Text(book.description!)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(Color.text(for: colorScheme))
            }
            .padding(.horizontal)
            .accessibility(label: Text("Description: \(book.description ?? "")"))

            // Add Rating Section after description

            Spacer(minLength: 30)

            // Action Button based on status
            actionButton
                .padding()
        }
    }

    // MARK: - Reviews Section Content
    // Using a method instead of a computed property to avoid naming conflicts
    private func reviewsSectionContent() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ReviewsSection(book: book)
        }
        .accessibilityElement(children: .contain)
    }

    // Action button based on status
    private var actionButton: some View {
        Button(action: {
            // Action based on current status
            Task {
                switch bookStatus {
                case .available, .completed:
                    withAnimation {
                        isBorrowLoading = true
                    }
                    do {
                        reservation = try await ReservationHandler.shared.reserve(bookId: book.id)
                        if var user = user {
                            user.reserved_book_ids.append(book.id)
                            UserCacheManager.shared.cacheUser(user)
                            self.user = user
                        }
                        isReserved = true
                        bookStatus = .requested
                        withAnimation(.easeOut(duration: 0.3)) {
                            isBorrowLoading = false
                        }
                    } catch {
                        withAnimation {
                            isBorrowLoading = false
                            // Handle error state if needed
                        }
                    }
                case .reading:
                    break
                case .requested:
                    withAnimation {
                        isBorrowLoading = true
                    }
                    do {
                        let reservation = try await ReservationHandler.shared
                            .getReservationForBookId(book.id)
                        if reservation != nil {
                            try await ReservationHandler.shared.cancelReservation(reservation!.id)
                        }
                        if user != nil {
                            if let index = user!.reserved_book_ids.firstIndex(of: book.id) {
                                user!.reserved_book_ids.remove(at: index)
                            }
                            UserCacheManager.shared.cacheUser(user!)
                        }
                        isReserved = false
                        bookStatus = .available
                        withAnimation(.easeOut(duration: 0.3)) {
                            isBorrowLoading = false
                        }
                    } catch {
                        withAnimation {
                            isBorrowLoading = false
                        }
                    }
                case .notAvailable, .loading:
                    break
                }
            }
        }) {
            ZStack {
                // Background and text (hidden during loading)
                Text(actionButtonText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(actionButtonColor)
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(10)
                    .opacity(isBorrowLoading ? 0 : 1)

                // Loading indicator
                if isBorrowLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: Color.text(for: colorScheme))
                            )
                            .scaleEffect(0.8)

                        Text(loadingText())
                            .font(.subheadline)
                            .foregroundColor(Color.text(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(actionButtonColor)
                    .cornerRadius(10)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isBorrowLoading)
            .disabled(isBorrowLoading)
        }
        .accessibility(label: Text(actionButtonText))
        .accessibility(hint: Text(buttonAccessibilityHint()))
    }

    // Helper function to provide context-aware loading text
    private func loadingText() -> String {
        switch bookStatus {
        case .available:
            return "Borrowing..."
        case .requested:
            return "Canceling..."
        case .loading:
            return "Loading..."
        default:
            return "Processing..."
        }
    }

    // Helper function for accessibility hints
    private func buttonAccessibilityHint() -> String {
        switch bookStatus {
        case .available:
            return "Double tap to borrow this book"
        case .requested:
            return "Double tap to cancel your reservation"
        case .reading:
            return "Double tap to return this book"
        case .completed:
            return "Double tap to borrow this book again"
        case .notAvailable:
            return "This book is not currently available"
        case .loading:
            return "Loading book status"
        }
    }

    private var actionButtonText: String {
        switch bookStatus {
        case .available:
            return "Borrow"
        case .reading:
            return "Return to libraray"
        case .requested:
            return "Cancel Request"
        case .completed:
            return "Borrow again"

        case .notAvailable:
            return "Not Available"
        case .loading:
            return "Loading..."
        }
    }

    private var actionButtonColor: Color {
        switch bookStatus {
        case .available, .loading, .completed:
            return Color.primary(for: colorScheme).opacity(0.6)
        case .reading:
            return .gray.opacity(0.2)
        case .requested, .notAvailable:
            return .red.opacity(0.8)

        }
    }

    // MARK: - Book Club Section
    private var bookClubSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isLoadingBookClubInsights {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)

                    Text("Generating book club insights...")
                        .font(.headline)
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if let error = bookClubError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.top, 30)

                    Text("Couldn't generate insights")
                        .font(.headline)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        fetchBookClubInsights()
                    }) {
                        Text("Try Again")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity)
            } else if bookClubQuestions.isEmpty && bookClubThemes.isEmpty && bookClubFacts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 50))
                        .foregroundColor(Color.accent(for: colorScheme).opacity(0.7))
                        .padding(.top, 30)

                    Text("Get AI-Generated Book Club Insights")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(
                        "Generate discussion questions, explore themes, and discover interesting facts about this book."
                    )
                    .font(.subheadline)
                    .foregroundColor(Color.secondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                    Button(action: {
                        fetchBookClubInsights()
                    }) {
                        Text("Generate Insights")
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accent(for: colorScheme).opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Discussion Questions
                        if !bookClubQuestions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "questionmark.bubble.fill")
                                        .foregroundColor(Color.accent(for: colorScheme))
                                    Text("Discussion Questions")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .padding(.bottom, 4)

                                ForEach(Array(bookClubQuestions.enumerated()), id: \.offset) {
                                    index, question in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(index + 1).")
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.accent(for: colorScheme))

                                        Text(question)
                                            .foregroundColor(Color.text(for: colorScheme))
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary(for: colorScheme).opacity(0.1))
                            )
                            .padding(.horizontal)
                        }

                        // Themes
                        if !bookClubThemes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "rectangle.3.group.fill")
                                        .foregroundColor(Color.accent(for: colorScheme))
                                    Text("Key Themes")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .padding(.bottom, 4)

                                ForEach(bookClubThemes, id: \.self) { theme in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(Color.accent(for: colorScheme))
                                            .padding(.top, 6)

                                        Text(theme)
                                            .foregroundColor(Color.text(for: colorScheme))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary(for: colorScheme).opacity(0.1))
                            )
                            .padding(.horizontal)
                        }

                        // Interesting Facts
                        if !bookClubFacts.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Color.accent(for: colorScheme))
                                    Text("Interesting Facts")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .padding(.bottom, 4)

                                ForEach(bookClubFacts, id: \.self) { fact in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.accent(for: colorScheme))
                                            .padding(.top, 3)

                                        Text(fact)
                                            .foregroundColor(Color.text(for: colorScheme))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary(for: colorScheme).opacity(0.1))
                            )
                            .padding(.horizontal)
                        }

                        // Refresh button
                        Button(action: {
                            fetchBookClubInsights()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Insights")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accent(for: colorScheme).opacity(0.15))
                            .cornerRadius(10)
                            .foregroundColor(Color.accent(for: colorScheme))
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .padding(.top)
        .onAppear {
            // Only fetch insights if we haven't already
            if bookClubQuestions.isEmpty && bookClubThemes.isEmpty && bookClubFacts.isEmpty {
                // Don't auto-fetch, let the user choose when to generate
                // fetchBookClubInsights()
            }
        }
    }

    private func fetchBookClubInsights() {
        isLoadingBookClubInsights = true
        bookClubError = nil

        Task {
            do {
                // Create prompt for Gemini API
                let title = book.title
                let description = book.description ?? "No description available"
                let authors = book.authorNames?.joined(separator: ", ") ?? "Unknown author"

                let prompt = """
                    For the book "\(title)" by \(authors), with this description: "\(description.prefix(500))", 
                    please generate book club insights in JSON format with these sections:

                    1. discussionQuestions: 3-5 thought-provoking questions that would spark meaningful conversation in a book club
                    2. themes: 3-4 major themes present in the book with brief descriptions
                    3. interestingFacts: 2-3 interesting facts related to the book, its author, or its context

                    Return the response in valid JSON format like this:
                    {
                      "discussionQuestions": ["Question 1", "Question 2", "Question 3"],
                      "themes": ["Theme 1: Description", "Theme 2: Description"],
                      "interestingFacts": ["Fact 1", "Fact 2"]
                    }
                    """

                // Call Gemini API through FolioService
                let response = try await FolioService.shared.generateBookClubInsights(
                    prompt: prompt)

                // Parse the response and update UI
                await MainActor.run {
                    bookClubQuestions = response.discussionQuestions
                    bookClubThemes = response.themes
                    bookClubFacts = response.interestingFacts
                    isLoadingBookClubInsights = false
                }
            } catch {
                print("Error generating book club insights: \(error.localizedDescription)")
                await MainActor.run {
                    bookClubError = "Could not generate insights. Please try again later."
                    isLoadingBookClubInsights = false
                }
            }
        }
    }
}

// MARK: - Book status enum to handle different states
enum BookStatus {
    case available
    case reading
    case requested
    case completed(dueDate: Date)
    case notAvailable
    case loading

    var displayText: String {
        switch self {
        case .available:
            return "Available"
        case .reading:
            return "Reading"
        case .requested:
            return "Requested"
        case .loading:
            return "Loading..."
        case .notAvailable:
            return "Not Available"
        case .completed:
            return "Completed"

        }
    }
}
//    var displayTextcolor: Color {
//        switch self {
//        case .available:
//            return Color.primary(for: colorScheme)
//        case .reading:
//            return "Reading"
//        case .requested:
//            return "Requested"
//        case .loading:
//            return "Loading..."
//        case .notAvailable:
//            return "Not Available"
//        case .completed:
//           return "Completed"
//
//        }
//    }
