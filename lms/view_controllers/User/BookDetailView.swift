import SwiftUI

struct BookDetailView: View {
    let book: BookModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    // State to track book status (you might want to move this to your Book model)
    @State private var bookStatus: BookStatus = .available

    // Add rating state
    @State private var userRating: Int = 0

    // Add bookmark state
    @State private var isBookmarked: Bool = false

    // Add tab selection state
    @State private var selectedTab: TabSection = .details

    enum TabSection: String, CaseIterable {
        case details = "Description"
        case reviews = "Reviews"
    }
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

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

                    Spacer()

                    // Navigation title
                    Text("Book Details")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.text(for: colorScheme))

                    Spacer()

                    // Bookmark button moved to navigation bar
                    Button(action: {
                        Task{
                            if(!isBookmarked){
                                isBookmarked.toggle()
                                LoginManager.shared.addToWishlist(bookId: book.id)
                                do{
                                    try await addToWishlistAPI(bookId: book.id)
                                }
                            }
                            else {
                                LoginManager.shared.removeFromWishlist(bookId: book.id)
                                isBookmarked.toggle()
                                do{
                                    try await removeWishListApi(bookId: book.id)
                                }
                            }
                        }
                    }) {
                        Image(
                            systemName: isBookmarked
                                ? "bookmark.fill" : "bookmark"
                        )
                        .font(.system(size: 22))
                        .foregroundColor(isBookmarked ? .black : .gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
//                .background(Color.background(for: colorScheme).opacity(0.8)) // Using your color system

                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
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
                                    .padding(.leading)
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

                                Image(systemName: "book.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                // Title in larger font like the image
                                Text(book.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .padding(.top, 5)

                                // Author with "by" prefix as shown in the image
                                Text("by Author XYZ")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))

                                
                            }
                            .padding(.trailing)
                            
                        }
//                        .padding(.vertical)
                        // Status badge - made to look like the blue button in the image
                        Text(bookStatus.displayText)
                            .font(.system(size: 18))
                            .foregroundColor(Color.green)
//                            .cornerRadius(20)
                            .padding(.leading,16)

                        // Genre tags in a horizontal scroll - styling similar to the teal buttons in the image
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(book.genreNames!, id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            Color.secondary(for: colorScheme).opacity(0.5)
                                        )
                                        .foregroundColor(Color.text(for: colorScheme))
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal)
                        }

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
                            }
                        }
                        .padding(.horizontal)
//                        .background(Color.accent(for: colorScheme).opacity(0.2))

                        // Content based on selected tab
                        switch selectedTab {
                        case .details:
                            detailsSection
                        case .reviews:
                            reviewsSectionContent()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .onAppear {
                if let cachedUser = UserCacheManager.shared.getCachedUser() {
                    self.isBookmarked = cachedUser.wishlist_book_ids.contains(book.id)
                }
                loadCoverImage()
            }
            .navigationBarHidden(true)
        }
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
    }

    // Action button based on status
    private var actionButton: some View {
        Button(action: {
            // Action based on current status
            switch bookStatus {
            case .available:
                bookStatus = .reading
            case .reading:
                bookStatus = .available
            case .requested:
                bookStatus = .available
            case .completed:
                bookStatus = .available
            }
        }) {
            Text(actionButtonText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(actionButtonColor)
                .foregroundColor(Color.text(for: colorScheme))
                .cornerRadius(10)
        }
    }

    private var actionButtonText: String {
        switch bookStatus {
        case .available:
            return "Borrow"
        case .reading:
            return "Return Book"
        case .requested:
            return "Cancel Request"
        case .completed:
            return "Return Now"
        }
    }

    private var actionButtonColor: Color {
        switch bookStatus {
        case .available:
            return Color.accent(for: colorScheme)
        case .reading:
            return .green
        case .requested:
            return .gray
        case .completed:
            return .red
        }
    }
}

// MARK: - Book status enum to handle different states
enum BookStatus {
    case available
    case reading
    case requested
    case completed(dueDate: Date)

    var displayText: String {
        switch self {
        case .available:
            return "Available"
        case .reading:
            return "Reading"
        case .requested:
            return "Requested"
        case .completed(let dueDate):
            if dueDate < Date() {
                return "Overdue"
            } else {
                return "Due \(dueDate.formatted(.dateTime.day().month()))"
            }
        }
    }
}


