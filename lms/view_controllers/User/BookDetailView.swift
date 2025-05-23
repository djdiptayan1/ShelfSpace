import Combine
import Foundation
import SwiftUI
// UIKit is not directly used in BookDetailView, but UIImage is.
// If UIImage is the only thing, Foundation and SwiftUI are usually enough for its Data representation.
// However, if you load UIImage directly from UIKit elsewhere, keep it. For this file:
import UIKit // Keep for UIImage, though often SwiftUI's Image(uiImage:) handles it.

// MARK: - BookStatus Enum (Corrected)
enum BookStatus: Codable { // Make it Codable if you need to save/load it directly
    case available
    case reading
    case requested
    case completed(dueDate: Date) // If you need to encode/decode Date, ensure it's handled
    case notAvailable
    case loading

    // You'll need custom Codable conformance if you have associated values like `dueDate`
    // For simplicity, if `completed` doesn't *need* to be Codable with its Date,
    // you might make the enum not Codable or handle it manually.
    // Let's assume for now you might not directly encode/decode BookStatus with its associated value.
    // If you do, you'll need init(from:) and encode(to:).

    // Add displayText back
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

    func badgeBackgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .available:
            return .green.opacity(0.8)
        case .reading:
            return Color.blue.opacity(0.8)
        case .requested:
            return Color.orange.opacity(0.8)
        case .completed:
            return Color.purple.opacity(0.8)
        case .notAvailable:
            return Color.gray.opacity(0.5)
        case .loading:
            return Color.secondary(for: colorScheme).opacity(0.3)
        }
    }

    func badgeTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .available, .reading, .requested, .completed:
            return .white
        case .notAvailable:
            return Color.text(for: colorScheme).opacity(0.9)
        case .loading:
            return Color.text(for: colorScheme).opacity(0.7)
        }
    }

    // Custom Codable conformance to handle associated value if needed
    // This is a common pattern for enums with associated values.
    enum CodingKeys: String, CodingKey {
        case type
        case dueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "available": self = .available
        case "reading": self = .reading
        case "requested": self = .requested
        case "completed":
            let date = try container.decode(Date.self, forKey: .dueDate)
            self = .completed(dueDate: date)
        case "notAvailable": self = .notAvailable
        case "loading": self = .loading
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid BookStatus type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .available:
            try container.encode("available", forKey: .type)
        case .reading:
            try container.encode("reading", forKey: .type)
        case .requested:
            try container.encode("requested", forKey: .type)
        case .completed(let dueDate):
            try container.encode("completed", forKey: .type)
            try container.encode(dueDate, forKey: .dueDate)
        case .notAvailable:
            try container.encode("notAvailable", forKey: .type)
        case .loading:
            try container.encode("loading", forKey: .type)
        }
    }
}

// Add a way to compare BookStatus if needed, especially with associated values
extension BookStatus: Equatable {
    static func == (lhs: BookStatus, rhs: BookStatus) -> Bool {
        switch (lhs, rhs) {
        case (.available, .available),
             (.reading, .reading),
             (.requested, .requested),
             (.notAvailable, .notAvailable),
             (.loading, .loading):
            return true
        case (.completed(let lhsDate), .completed(let rhsDate)):
            return lhsDate == rhsDate // Or some other comparison logic for dates
        default:
            return false
        }
    }
}


struct BookDetailView: View {
    @State var book: BookModel
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    @State private var bookStatus: BookStatus = .loading // Now this will work
    @State private var userRating: Int = 0
    @State private var isBookmarked: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedTab: TabSection = .details

    enum TabSection: String, CaseIterable {
        case details = "Description"
        case reviews = "Reviews"
    }
    @State private var loadedImage: UIImage? = nil
    @State private var isLoadingImage: Bool = false
    @State private var loadImageError: Bool = false

    @State private var user: User?
    @State private var isActionLoading: Bool = false
    @State private var borrow: BorrowModel?
    @State private var reservation: ReservationModel?
    @State private var isBorrowed = false
    @State private var isReserved = false

    @State private var bookClubQuestions: [String] = []
    @State private var bookClubThemes: [String] = []
    @State private var bookClubFacts: [String] = []
    @State private var isLoadingBookClubInsights: Bool = false
    @State private var bookClubError: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            ReusableBackground(colorScheme: colorScheme)

            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.medium))
                            .foregroundColor(Color.text(for: colorScheme))
                    }
                    .padding(8)
                    .accessibility(label: Text("Back"))
                    .accessibility(hint: Text("Double tap to go back to previous screen"))

                    Spacer()

                    Text("Book Details")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.text(for: colorScheme))
                        .accessibility(addTraits: .isHeader)

                    Spacer()

                    Button(action: toggleBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundColor(
                                isBookmarked
                                    ? Color.accent(for: colorScheme)
                                    : Color.text(for: colorScheme).opacity(0.7)
                            )
                    }
                    .padding(8)
                    .accessibility(
                        label: Text(isBookmarked ? "Remove from bookmarks" : "Add to bookmarks")
                    )
                    .accessibility(hint: Text("Double tap to toggle bookmark status"))
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    ReusableBackground(colorScheme: colorScheme).edgesIgnoringSafeArea(.top)
                )
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.secondary(for: colorScheme).opacity(0.3)),
                    alignment: .bottom
                )

                // MARK: - Main Content ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Book Cover and Primary Details
                        HStack(alignment: .top, spacing: 16) {
                            // Book Cover Image
                            Group {
                                if isLoadingImage {
                                    ProgressView()
                                        .frame(width: 150, height: 220)
                                        .background(Color.secondary(for: colorScheme).opacity(0.1))
                                        .cornerRadius(12)
                                } else if let image = loadedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 150, height: 220)
                                        .cornerRadius(12)
                                        .shadow(
                                            color: Color.black.opacity(
                                                colorScheme == .dark ? 0.4 : 0.15),
                                            radius: 8, x: 0, y: 4
                                        )
                                        .clipped()
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.secondary(for: colorScheme).opacity(
                                                            0.2),
                                                        Color.secondary(for: colorScheme).opacity(
                                                            0.05),
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        Image(systemName: "book.closed.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(
                                                Color.text(for: colorScheme).opacity(0.4))
                                    }
                                    .frame(width: 150, height: 220)
                                }
                            }
                            .padding(.leading)
                            .animation(.easeInOut(duration: 0.3), value: loadedImage)
                            .animation(.easeInOut(duration: 0.3), value: isLoadingImage)
                            .accessibility(hidden: true)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(book.title)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibility(addTraits: .isHeader)

                                Text("by " + (book.authorNames?.first ?? "Unknown Author"))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(Color.text(for: colorScheme).opacity(0.75))

                                // Status Badge - Improved Styling
                                Text(bookStatus.displayText) // This will now work
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(bookStatus.badgeBackgroundColor(for: colorScheme))
                                    .foregroundColor(bookStatus.badgeTextColor(for: colorScheme))
                                    .clipShape(Capsule())
                                    .padding(.top, 6)
                                    .accessibility(
                                        label: Text("Book status: \(bookStatus.displayText)"))
                            }
                            .padding(.trailing)
                            .padding(.top, 5)
                        }
                        .padding(.top, 5)

                        // MARK: - Genre Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(book.genreNames ?? [], id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 13, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.primary(for: colorScheme).opacity(0.2))
                                        .foregroundColor(Color.text(for: colorScheme))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibility(
                            label: Text("Genres: \(book.genreNames?.joined(separator: ", ") ?? "")")
                        )

                        // MARK: - Tab Selector
                        HStack(spacing: 0) {
                            ForEach(TabSection.allCases, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Text(tab.rawValue)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: selectedTab == tab ? .bold : .semibold)
                                            )
                                            .foregroundColor(
                                                selectedTab == tab
                                                    ? Color.accent(for: colorScheme)
                                                    : Color.text(for: colorScheme).opacity(0.6)
                                            )
                                            .padding(.horizontal, 8)

                                        if selectedTab == tab {
                                            Capsule()
                                                .frame(height: 3)
                                                .foregroundColor(Color.accent(for: colorScheme))
                                                .padding(.horizontal, 8)
                                        } else {
                                            Rectangle().frame(height: 3).foregroundColor(.clear)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .accessibility(label: Text(tab.rawValue))
                                .accessibility(
                                    addTraits: selectedTab == tab
                                        ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .padding(.horizontal, 8)
                        .background(Color.secondary(for: colorScheme).opacity(0.07))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .accessibilityElement(children: .contain)
                        .accessibility(label: Text("Tabs"))
                        .accessibility(hint: Text("Swipe left or right to navigate between tabs"))

                        // MARK: - Content based on selected tab
                        Group {
                            switch selectedTab {
                            case .details:
                                detailsSection
                            case .reviews:
                                reviewsSectionContent()
                            }
                        }
                        .transition(.opacity.combined(with: .slide))
                        .animation(.easeInOut, value: selectedTab)

                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear(perform: initialLoadTasks)
            .onReceive(
                BookHandler.shared.socketHandler.messagePublisher.receive(on: DispatchQueue.main)
            ) { message in
                if message.type == "bookUpdated", message.data.id == book.id {
                    book = message.data
                }
            }
            .navigationBarHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibility(label: Text("Book details for \(book.title)"))
    }

    private func initialLoadTasks() {
        loadCoverImage()
        Task {
            let wishlist = try? await getWishList()
            isBookmarked = wishlist?.contains(where: { $0.id == book.id }) ?? false
        }
        if bookClubThemes.isEmpty && bookClubFacts.isEmpty && !isLoadingBookClubInsights {
            fetchBookClubInsights()
        }
        Task {
            await updateUserAndBookStatus()
        }
    }

    private func toggleBookmark() {
        Task {
            let originalBookmarkState = isBookmarked
            isBookmarked.toggle()

            if isBookmarked {
                LoginManager.shared.addToWishlist(bookId: book.id)
                do {
                    try await addToWishlistAPI(bookId: book.id)
                } catch {
                    isBookmarked = originalBookmarkState
                    LoginManager.shared.removeFromWishlist(bookId: book.id)
                }
            } else {
                LoginManager.shared.removeFromWishlist(bookId: book.id)
                do {
                    try await removeWishListApi(bookId: book.id)
                } catch {
                    isBookmarked = originalBookmarkState
                    LoginManager.shared.addToWishlist(bookId: book.id)
                }
            }
        }
    }

    private func updateUserAndBookStatus() async {
        self.isActionLoading = true
        // bookStatus = .loading // This is already the default, ensure it's the enum case
        do {
            user = try await LoginManager.shared.getCurrentUser()
            let currentBorrow = try? await BorrowHandler.shared.getBorrowForBookId(book.id)
            let currentReservation = try? await ReservationHandler.shared.getReservationForBookId(
                book.id)

            self.borrow = currentBorrow
            self.reservation = currentReservation

            if currentReservation != nil {
                bookStatus = .requested
            } else if let brw = currentBorrow {
                isBorrowed = true
                bookStatus = brw.status == .borrowed ? .reading : .completed(dueDate: Date())
            } else if book.availableCopies == 0 {
                bookStatus = .notAvailable
            } else {
                bookStatus = .available
            }
        } catch {
            print("Error fetching user/book status: \(error)")
            bookStatus = .notAvailable
        }
        isActionLoading = false
    }

    // MARK: - Image Loading
    private func loadCoverImage() {
        isLoadingImage = true
        loadImageError = false

        if let imageData = book.coverImageData, let img = UIImage(data: imageData) {
            loadedImage = img
            isLoadingImage = false
            return
        }

        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoadingImage = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoadingImage = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingImage = false
                if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                    loadImageError = true
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    loadedImage = image
                } else {
                    loadImageError = true
                }
            }
        }.resume()
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.secondary(for: colorScheme).opacity(0.2))
                .padding(.horizontal)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 12) {
                Text("Synopsis")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.text(for: colorScheme))

                Text(book.description ?? "No description available.")
                    .font(.body)
                    .lineSpacing(5)
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.85))
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibility(
                label: Text("Synopsis: \(book.description ?? "No description available.")"))

            bookClubInsightsView

            Spacer(minLength: 20)

            actionButton
        }
        .padding(.bottom)
    }

    // MARK: - Book Club Insights View
    private var bookClubInsightsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.title2)
                    .foregroundColor(Color.accent(for: colorScheme))
                Text("Book Insights")
                    .font(.title3.bold())
                    .foregroundColor(Color.text(for: colorScheme))
            }
            .padding([.horizontal, .top])

            if isLoadingBookClubInsights {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Generating brilliant insights...")
                        .font(.callout)
                        .foregroundColor(Color.secondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let error = bookClubError {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red.opacity(0.8))
                    Text(error)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.text(for: colorScheme))
                        .padding(.horizontal)
                    Button(action: fetchBookClubInsights) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.accent(for: colorScheme))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if bookClubThemes.isEmpty && bookClubFacts.isEmpty && bookClubQuestions.isEmpty {
                Button(action: fetchBookClubInsights) {
                    Label("Unlock Book Insights", systemImage: "wand.and.stars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accent(for: colorScheme).opacity(0.9),
                                    Color.accent(for: colorScheme),
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.accent(for: colorScheme).opacity(0.3), radius: 5, y: 3)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            } else {
                if !bookClubThemes.isEmpty {
                    InsightSectionView(
                        title: "Key Themes",
                        iconName: "text.bubble.fill",
                        items: bookClubThemes,
                        colorScheme: colorScheme,
                        accentColor: Color.accent(for: colorScheme)
                    )
                }
                if !bookClubFacts.isEmpty {
                    InsightSectionView(
                        title: "Interesting Facts",
                        iconName: "lightbulb.fill",
                        items: bookClubFacts,
                        itemIcon: "star.fill",
                        colorScheme: colorScheme,
                        accentColor: Color.accent(for: colorScheme)
                    )
                }
//                if !bookClubQuestions.isEmpty {
//                    InsightSectionView(
//                        title: "Discussion Starters",
//                        iconName: "questionmark.bubble.fill",
//                        items: bookClubQuestions,
//                        itemIcon: "quote.bubble.fill",
//                        colorScheme: colorScheme,
//                        accentColor: Color.accent(for: colorScheme)
//                    )
//                }

                Button(action: fetchBookClubInsights) {
                    Label("Refresh Insights", systemImage: "arrow.clockwise.circle")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary(for: colorScheme).opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(Color.accent(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Reviews Section Content
    private func reviewsSectionContent() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ReviewsSection(book: book)
        }
        .padding()
        .accessibilityElement(children: .contain)
    }

    // MARK: - Action Button & Helpers
    private var actionButton: some View {
        Button(action: handleActionButtonTap) {
            ZStack {
                HStack(spacing: 10) {
                    if !isActionLoading {
                        Image(systemName: actionButtonIconName)
                            .font(.headline)
                    }
                    Text(actionButtonText)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(actionButtonColor)
                .foregroundColor(actionButtonTextColor)
                .cornerRadius(12)
                .shadow(
                    color: actionButtonShouldBeEnabled ? actionButtonColor.opacity(0.3) : .clear,
                    radius: 5, y: 3
                )
                .opacity(isActionLoading ? 0 : 1)

                if isActionLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: actionButtonTextColor))
                        Text(loadingText())
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(actionButtonColor.opacity(0.8))
                    .foregroundColor(actionButtonTextColor)
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.interactiveSpring(), value: isActionLoading)
        }
        .disabled(!actionButtonShouldBeEnabled || isActionLoading)
        .padding(.horizontal)
        .padding(.bottom)
        .accessibility(label: Text(actionButtonText))
        .accessibility(hint: Text(buttonAccessibilityHint()))
    }

    private func handleActionButtonTap() {
        Task {
            isActionLoading = true
            do {
                switch bookStatus {
                case .available, .completed:
                    // This part seems fine
                    let newReservation = try await ReservationHandler.shared.reserve(bookId: book.id) // Capture the new reservation
                    self.reservation = newReservation // Update the @State variable
                    if var u = user {
                        u.reserved_book_ids.append(book.id)
                        UserCacheManager.shared.cacheUser(u)
                        self.user = u
                    }
                    isReserved = true
                    bookStatus = .requested

                case .reading:
                    print("Return to library action")
                    // Ensure you have logic here if it's a possible state for the button
                    break

                case .requested:
                    // --- Problematic Area ---
                    // Corrected logic for getting the reservation to cancel:
                    var reservationToCancel: ReservationModel? = self.reservation // Use the existing @State

                    if reservationToCancel == nil {
                        // If the @State variable is nil for some reason, try fetching it again
                        print("Local reservation state was nil, attempting to fetch from handler for book ID: \(book.id)")
                        reservationToCancel = try await ReservationHandler.shared.getReservationForBookId(book.id)
                    }

                    if let res = reservationToCancel {
                        try await ReservationHandler.shared.cancelReservation(res.id)
                        if var u = user, let index = u.reserved_book_ids.firstIndex(of: book.id) {
                            u.reserved_book_ids.remove(at: index)
                            UserCacheManager.shared.cacheUser(u)
                            self.user = u
                        }
                        isReserved = false
                        self.reservation = nil // Clear the @State variable
                        bookStatus = book.availableCopies > 0 ? .available : .notAvailable
                    } else {
                        // This case means no reservation was found locally or fetched,
                        // which might indicate an inconsistent state.
                        // You might want to refresh the status or show an error.
                        print("Error: Could not find reservation to cancel for book ID: \(book.id). Refreshing status.")
                        await updateUserAndBookStatus() // Refresh to get consistent state
                    }

                case .notAvailable, .loading:
                    break
                }
            } catch {
                print("Action button error: \(error)")
                // It's good to refresh the status on any error during action.
                await updateUserAndBookStatus()
            }
            // Ensure isActionLoading is set to false regardless of success or failure within the Task.
            // It was correctly placed outside the do-catch.
            isActionLoading = false
        }
    }

    private var actionButtonShouldBeEnabled: Bool {
        switch bookStatus {
        case .available, .completed, .reading, .requested:
            return true
        case .notAvailable, .loading:
            return false
        }
    }

    private var actionButtonIconName: String {
        switch bookStatus {
        case .available, .completed: return "arrow.down.circle.fill"
        case .reading: return "arrow.uturn.left.circle.fill"
        case .requested: return "xmark.circle.fill"
        case .notAvailable, .loading: return "hourglass"
        }
    }

    private var actionButtonText: String {
        switch bookStatus {
        case .available: return "Borrow"
        case .reading: return "Return to Library"
        case .requested: return "Cancel Request"
        case .completed: return "Borrow Again"
        case .notAvailable: return "Not Available"
        case .loading: return "Loading Status..."
        }
    }

    private var actionButtonColor: Color {
        guard actionButtonShouldBeEnabled else { return .gray.opacity(0.4) }
        switch bookStatus {
        case .available, .completed: return Color.primary(for: colorScheme)
        case .reading: return Color.orange.opacity(0.9)
        case .requested: return .red.opacity(0.85)
        default: return .gray.opacity(0.4)
        }
    }

    private var actionButtonTextColor: Color {
        guard actionButtonShouldBeEnabled else { return Color.primary(for: colorScheme).opacity(0.7) }
        switch bookStatus {
        case .available, .completed, .reading, .requested:
            return .white
        default:
            return Color.text(for: colorScheme).opacity(0.7)
        }
    }

    private func loadingText() -> String {
        switch bookStatus {
        case .available, .completed: return "Requesting..."
        case .reading: return "Returning..."
        case .requested: return "Canceling..."
        default: return "Processing..."
        }
    }

    private func buttonAccessibilityHint() -> String {
        switch bookStatus {
        case .available: return "Double tap to borrow this book"
        case .reading: return "Double tap to return this book to the library"
        case .requested: return "Double tap to cancel your reservation for this book"
        case .completed: return "Double tap to borrow this book again"
        case .notAvailable: return "This book is not currently available"
        case .loading: return "Loading book status"
        }
    }

    // MARK: - Book Club Insights Fetching
    private func fetchBookClubInsights() {
        isLoadingBookClubInsights = true
        bookClubError = nil

        Task {
            do {
                let title = book.title
                let description = book.description ?? "No description available"
                let authors = book.authorNames?.joined(separator: ", ") ?? "Unknown author"
                let prompt = """
                    For the book "\(title)" by \(authors), with this description: "\(description.prefix(500))", 
                    please generate book club insights in JSON format. Include these sections:
                    1. discussionQuestions: 3-4 thought-provoking questions for a book club.
                    2. themes: 3-4 major themes with brief descriptions (e.g., "Theme Name: A short explanation.").
                    3. interestingFacts: 2-3 concise, interesting facts about the book, its author, or context.

                    Return valid JSON:
                    {
                      "discussionQuestions": ["Question 1?", "Question 2?"],
                      "themes": ["Theme 1: Description", "Theme 2: Description"],
                      "interestingFacts": ["Fact 1.", "Fact 2."]
                    }
                    """
                let response = try await FolioService.shared.generateBookClubInsights(
                    prompt: prompt)
                await MainActor.run {
                    bookClubQuestions = response.discussionQuestions
                    bookClubThemes = response.themes
                    bookClubFacts = response.interestingFacts
                    isLoadingBookClubInsights = false
                }
            } catch {
                await MainActor.run {
                    bookClubError = "Could not generate insights. Please try again."
                    isLoadingBookClubInsights = false
                }
            }
        }
    }
}

// MARK: - InsightSectionView (New Reusable View)
struct InsightSectionView: View {
    let title: String
    let iconName: String
    let items: [String]
    var itemIcon: String = "circle.fill"
    let colorScheme: ColorScheme
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.text(for: colorScheme))
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: itemIcon)
                        .font(.system(size: itemIcon == "circle.fill" ? 7 : 10))
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(.top, itemIcon == "circle.fill" ? 6 : 4)

                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color.secondary(for: colorScheme).opacity(0.08))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
