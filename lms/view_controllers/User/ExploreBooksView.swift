//
//  ExploreBooksView.swift
//  lms
//
//  Created by Navdeep Lakhlan on 03/05/25.
//
import SwiftUI

struct ExploreBooksView: View {
    // MARK: - Properties

    @StateObject private var explorePaginationManager = BookPaginationManager()
    @State private var allBooks: [BookModel] = []

    @State private var searchText = ""
    @State private var selectedGenres: Set<String> = []
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoadingInitial = false

    // Updated to use BookGenre structure from HomeView
    let categories = BookGenre.fictionGenres + BookGenre.nonFictionGenres

    var filteredBooks: [BookModel] {
        // Filters operate on `allBooks` which is populated by explorePaginationManager
        if searchText.isEmpty && selectedGenres.isEmpty {
            return allBooks
        }
        return allBooks.filter { book in
            let matchesSearch = searchText.isEmpty ||
                book.title.lowercased().contains(searchText.lowercased())
                (book.authorNames?.contains { $0.lowercased().contains(searchText.lowercased()) } ?? false) ||
                (book.genreNames?.contains { $0.lowercased().contains(searchText.lowercased()) } ?? false)
            let matchesGenre = selectedGenres.isEmpty ||
                !selectedGenres.isDisjoint(with: book.genreNames ?? [])
            return matchesSearch && matchesGenre
        }
    }

    var isFiltering: Bool {
        return !searchText.isEmpty || !selectedGenres.isEmpty
    }

    // MARK: - Main Body

    var body: some View {
        GeometryReader { _ in
            NavigationView {
                ZStack {
                    // Background gradient
                    ReusableBackground(colorScheme: colorScheme)

                    VStack(spacing: 0) {
                        // Sticky header with search
                        VStack(spacing: 16) {
                            SearchBarUser(
                                text: $searchText,
                                onCommit: {},
                                onClear: {
                                    searchText = ""
                                    selectedGenres = []
                                }
                            )
                            .accessibilityLabel("Search books")
                            .accessibilityHint("Type to search for books by title, author or genre")
                            .onChange(of: searchText) { _ in
                                // Real-time search as user types
                            }

                            // Genre chips - updated to use the BookGenre structure
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.displayName) { category in
                                        GenreChipk(
                                            genre: category.displayName,
                                            isSelected: selectedGenres.contains(category.displayName),
                                            colorScheme: colorScheme,
                                            iconName: category.iconName
                                        ) {
                                            if selectedGenres.contains(category.displayName) {
                                                selectedGenres.remove(category.displayName)
                                            } else {
                                                selectedGenres.insert(category.displayName)
                                            }
                                        }
                                        .accessibilityLabel("\(category.displayName) genre")
                                        .accessibilityHint(selectedGenres.contains(category.displayName) ? "Selected. Double tap to deselect." : "Not selected. Double tap to select.")
                                        .accessibilityAddTraits(selectedGenres.contains(category.displayName) ? .isSelected : [])
                                    }
                                }
                                .padding(.horizontal)
                                .accessibilityElement(children: .combine)
                            }
                            .accessibilityLabel("Genre filters")
                        }
                        .padding(.top)
                        .padding(.bottom, 8)
                        .background(ReusableBackground(colorScheme: colorScheme))
                        .zIndex(1)

                        // IMPROVED BOOK GRID
                        if isLoadingInitial && allBooks.isEmpty {
                            ProgressView("Loading Books...")
                                .frame(maxHeight: .infinity)
                                .accessibilityLabel("Loading books")
                        } else if !filteredBooks.isEmpty || isFiltering { // Show grid if there are books or if filtering (even if results are empty)
                            ScrollView {
                                LazyVGrid(
                                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                                    spacing: 20
                                ) {
                                    ForEach(filteredBooks) { book in // Relies on BookModel being Identifiable via 'id'
                                        NavigationLink(destination: BookDetailView(book: book)) { // Assumed BookDetailView
                                            ImprovedBookCard(book: book, colorScheme: colorScheme)
                                                .accessibilityElement(children: .combine)
                                                .accessibilityLabel("\(book.title), by \(book.authorNames?.joined(separator: ", ") ?? "unknown author"). Genres: \(book.genreNames?.joined(separator: ", ") ?? "no genres")")
                                                .accessibilityHint("Double tap to view details")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }

                                    // Pagination Loader: Show only if not filtering and there are more pages
                                    if !isFiltering && explorePaginationManager.hasMorePages() {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .onAppear {
                                                    print("ExploreBooksView: Loader appeared, attempting to load more.")
                                                    triggerLoadMoreBooks()
                                                }
                                                .padding()
                                                .accessibilityLabel("Loading more books")
                                            Spacer()
                                        }
                                        .gridCellColumns(2) // Span across both columns
                                        .id("ExploreLoader-\(explorePaginationManager.currentPage)") // Unique ID to help onAppear trigger
                                    } else if !isFiltering && !explorePaginationManager.hasMorePages() && !allBooks.isEmpty && !explorePaginationManager.isLoading {
                                        Text("No more books to load.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding()
                                            .gridCellColumns(2)
                                            .accessibilityLabel("No more books to load")
                                    }
                                }
                                .padding()
                            }
                            .accessibilityLabel("Books grid")
                        } else if !isLoadingInitial && allBooks.isEmpty && !isFiltering {
                            Text("No books found in the library currently.")
                                .frame(maxHeight: .infinity)
                                .accessibilityLabel("No books found")
                        }
                    }
                }
                .navigationBarTitle("Explore Books", displayMode: .inline)
                .navigationBarHidden(true)
                .alert("Error", isPresented: $showError, actions: { Button("OK", role: .cancel) { } }, message: { Text(errorMessage ?? "An unknown error occurred") })
            }
            .accessibilityElement(children: .contain)
        }
        .foregroundColor(Color.text(for: colorScheme)) // Assumed Color.text definition
        .task {
            // Initial load when the view appears
            if allBooks.isEmpty { // Only load if not already populated (e.g. by cache on previous appearance)
                print("ExploreBooksView: .task triggered, loading initial books.")
                await loadInitialBooks()
            }
        }
        .refreshable {
            print("ExploreBooksView: Refresh triggered.")
            await loadInitialBooks(isRefresh: true)
        }
    }

    // MARK: - Helper Methods

    private func loadInitialBooks(isRefresh: Bool = false) async {
        guard !isLoadingInitial || isRefresh else { return } // Prevent multiple initial loads unless refreshing
        
        isLoadingInitial = true
        errorMessage = nil
        showError = false

        // For refresh, ensure the manager is reset.
        // fetchBooks with page:1 handles manager.reset()
        
        // Try loading from cache first, but only if not refreshing
        if !isRefresh {
            if let cachedBooks = BookHandler.shared.getCachedData() { // Use a view-specific key
                if !cachedBooks.isEmpty {
                    self.allBooks = cachedBooks
                    // Manually set manager state if loading from cache, or let fetch override
                    // This is tricky. Best to let fetchBooks establish manager state.
                    print("ExploreBooksView: Loaded \(cachedBooks.count) books from cache.")
                }
            }
        }
        fetchBooks(manager: explorePaginationManager, page: 1, limit: 200) { result in
            isLoadingInitial = false
            switch result {
            case .success(let booksFromManager):
                // `booksFromManager` is `explorePaginationManager.books`
                self.allBooks = booksFromManager
                print("ExploreBooksView: Initial books fetched. Count: \(self.allBooks.count). Manager: \(explorePaginationManager.currentPage)/\(explorePaginationManager.totalPages)")
                // Preload covers if needed
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
                print("[ERROR] ExploreBooksView: Failed to load initial books: \(error)")
            }
        }
    }

    private func triggerLoadMoreBooks() {
        // Guard against multiple loading requests, filtering, or if already loading by the manager
        guard !isFiltering, !isLoadingMore, !explorePaginationManager.isLoading, explorePaginationManager.hasMorePages() else {
            if isFiltering { print("ExploreBooksView: Load more skipped due to filtering.") }
            if isLoadingMore { print("ExploreBooksView: Load more skipped, already loading more.") }
            if explorePaginationManager.isLoading { print("ExploreBooksView: Load more skipped, manager is busy.") }
            if !explorePaginationManager.hasMorePages() { print("ExploreBooksView: Load more skipped, no more pages.") }
            return
        }

        isLoadingMore = true // UI state for this view's loader
        print("ExploreBooksView: Calling loadMoreBooks for manager. Current page: \(explorePaginationManager.currentPage)")

        // Use the global loadMoreBooks with our specific manager
        loadMoreBooks(manager: explorePaginationManager, limit: 200) { result in
            isLoadingMore = false
            switch result {
            case .success(let updatedBooksFromManager):
                // `updatedBooksFromManager` is `explorePaginationManager.books` which includes appended items
                 self.allBooks = updatedBooksFromManager
                print("ExploreBooksView: More books loaded. Total: \(self.allBooks.count). Manager: \(explorePaginationManager.currentPage)/\(explorePaginationManager.totalPages)")
            case .failure(let error):
                self.errorMessage = "Failed to load more books: \(error.localizedDescription)"
                self.showError = true
                print("[ERROR] ExploreBooksView: Failed to load more books: \(error)")
            }
        }
    }
}

private func preloadBookCover(for book: BookModel) {
        guard let urlString = book.coverImageUrl,
              let url = URL(string: urlString) else {
            return
        }

        URLSession.shared.dataTask(with: url).resume()
    }

struct ImprovedBookCard: View {
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book Cover Container - Fixed size with proper constraints
            ZStack {
                // Background for when image is loading or missing
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "A1C4FD"), Color(hex: "C2E9FB"),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Placeholder icon when no image is available
                if loadedImage == nil {
                    Image(systemName: "book.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.7))
                        .accessibilityHidden(true)
                }

                // The actual book cover image
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width / 2.5, height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: UIScreen.main.bounds.width / 2.5, height: 200)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding(.bottom, 8)
            .accessibilityHidden(true)

            // Text content container - Separated from image
            VStack(alignment: .leading, spacing: 4) {
                // Title with fixed height to ensure consistent spacing
                Text(book.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.text(for: colorScheme))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height:35)
                
               
                // Genre tags in a fixed height container
                if let genres = book.genreNames, !genres.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(genres.prefix(2), id: \.self) { genre in
                            Text(genre)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15)) /* primary(for: colorScheme).opacity(0.1)) */
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                                .cornerRadius(4)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(height: 20, alignment: .leading)
                } else {
                    Spacer()
                        .frame(height: 20)
                }
            }
            .padding(.horizontal, 4)
            .frame(width: UIScreen.main.bounds.width / 2.5)
            .padding(.bottom, 8)
        }
        .frame(width: UIScreen.main.bounds.width / 2.5)
        .padding(.vertical, 6)
        .background(Color.clear)
        .onAppear {
            loadCoverImage()
        }
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

        URLSession.shared.dataTask(with: url) { data, _, error in
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

// MARK: - Genre Chip View

struct GenreChipk: View {
    let genre: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)

                Text(genre)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Color.primary(for: colorScheme).opacity(0.5) :
                    Color.primary(for: colorScheme).opacity(0.2)
            )
            .foregroundColor(
                isSelected ?
                    Color.text(for: colorScheme) :
                    Color.text(for: colorScheme).opacity(0.8)
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ?
                            Color.primary(for: colorScheme) :
                            Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Preview

struct ExploreBooksView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreBooksView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            ExploreBooksView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

    // private func loadBooks() async {
    //     isLoading = true
    //     // Load cached books first for instant display
    //     allBooks = BookHandler.shared.getCachedData() ?? []

    //     fetchBooks { result in
    //         isLoading = false

    //         switch result {
    //         case let .success(fetchedBooks):
    //             // Update books without animation
    //             self.allBooks = fetchedBooks

    //             // Preload book covers for better UX
    //             for book in fetchedBooks where book.coverImageUrl != nil {
    //                 self.preloadBookCover(for: book)
    //             }
    //         case let .failure(error):
    //             self.errorMessage = error.localizedDescription
    //             self.showError = true
    //         }
    //     }
    // }

    // private func loadMoreBooks() {
    //     // Guard against multiple loading requests or filtering state
    //     guard !isFiltering && !isLoadingMore else { return }

    //     isLoadingMore = true
    //     lms.loadMoreBooks { result in
    //         self.isLoadingMore = false

    //         switch result {
    //         case let .success(updatedBooks):
    //             // Only update if we got new books (when count increases)
    //             if updatedBooks.count > self.allBooks.count {
    //                 // No animation when updating the collection
    //                 self.allBooks = updatedBooks
    //                 print("[DEBUG] (ExploreBooksView) Loaded more books. Total count: \(updatedBooks.count)")
    //             }
    //         case let .failure(error):
    //             self.errorMessage = "Failed to load more books: \(error.localizedDescription)"
    //             self.showError = true
    //             print("[ERROR] (ExploreBooksView) Failed to load more books: \(error)")
    //         }
    //     }
    // }

    
