import Foundation
import NavigationBarLargeTitleItems
import SwiftUI

struct HomeViewLibrarian: View {
    @StateObject private var homePaginationManager = BookPaginationManager()
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isShowingProfile = false
    @State private var prefetchedUser: User? = nil
    @State private var prefetchedLibrary: Library? = nil
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    @State private var isEditingBook = false
    @State private var editingBookId: UUID? = nil
    @State private var showImagePicker = false
    
    @State private var showProfileSheet = false

    @State private var library: Library?
    @State private var libraryName: String = "library loading..."

    @State private var books: [BookModel] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: BookGenre = .all
    @State private var showingAddBookSheet = false
    @State private var bookToEdit: BookModel?
    @State private var bookData = BookData()
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(prefetchedUser: User? = nil, prefetchedLibrary: Library? = nil) {
        self.prefetchedUser = prefetchedUser
        self.prefetchedLibrary = prefetchedLibrary
        library = prefetchedLibrary

        // Try to get library name from keychain
        if let name = try? KeychainManager.shared.getLibraryName() {
            _libraryName = State(initialValue: name)
        }
    }

    var filteredBooks: [BookModel] {
        var result = books
        if selectedCategory != .all {
            result = result.filter { $0.genreNames?.contains(selectedCategory.rawValue) == true }
        }
        if !searchText.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                    (book.isbn ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                    .accessibilityHidden(true) // Background doesn't need VoiceOver
                
                VStack(spacing: 0) {
                    headerSection
                        .padding(.bottom, 12)
                        .accessibilityElement(children: .combine)
                        .accessibilityHeading(.h1)

                    ScrollView {
                        VStack(spacing: 16) {
                            SearchBar(searchText: $searchText, colorScheme: colorScheme)
                                .accessibilityLabel("Search books")
                                .accessibilityHint("Type to search for books by title or ISBN")
                            
                            CategoryFilterView(
                                selectedCategory: $selectedCategory,
                                colorScheme: colorScheme
                            )
                            .accessibilityLabel("Filter by category")
                            .accessibilityValue(selectedCategory.rawValue)
                            
                            if isLoading {
                                LoadingAnimationView(colorScheme: colorScheme)
                                    .accessibilityLabel("Loading books")
                            } else {
                                if books.isEmpty {
                                    EmptyBookListView(colorScheme: colorScheme)
                                        .accessibilityLabel("No books available")
                                } else {
                                    BookList(
                                        books: filteredBooks,
                                        colorScheme: colorScheme,
                                        onEdit: { book in
                                            bookData = BookAddViewAdmin.bookData(from: book)
                                            // Load cover image from URL if needed
                                            if bookData.bookCover == nil, let urlStringRaw = book.coverImageUrl {
                                                let urlString = urlStringRaw.hasPrefix("http://") ? urlStringRaw.replacingOccurrences(of: "http://", with: "https://") : urlStringRaw
                                                if let url = URL(string: urlString) {
                                                    print("[DEBUG] (BookViewAdmin) Attempting to load cover image from URL: \(urlString)")
                                                    Task {
                                                        do {
                                                            let (data, _) = try await URLSession.shared.data(from: url)
                                                            if let image = UIImage(data: data) {
                                                                print("[DEBUG] (BookViewAdmin) Successfully loaded cover image from URL")
                                                                await MainActor.run {
                                                                    bookData.bookCover = image
                                                                }
                                                            } else {
                                                                print("[DEBUG] (BookViewAdmin) Failed to create UIImage from data")
                                                            }
                                                        } catch {
                                                            print("[DEBUG] (BookViewAdmin) Failed to load cover image from URL: \(error)")
                                                        }
                                                    }
                                                }
                                            }
                                            editingBookId = book.id
                                            isEditingBook = true
                                        },
                                        onDelete: deleteBook
                                    )
                                    .accessibilityLabel("List of books")
                                    
                                    // Add pagination loader at the bottom
                                    if !isFiltering {
                                        HStack {
                                            Spacer()
                                            if isLoadingMore {
                                                ProgressView()
                                                    .padding()
                                                    .accessibilityLabel("Loading more books")
                                            }
                                            Spacer()
                                        }
                                        .id("BottomLoader")
                                        .onAppear {
                                            loadMoreBooks()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        await loadBooks()
                    }
                    .accessibilityScrollAction { edge in
                        // Provide feedback when scrolling
                        UIAccessibility.post(notification: .announcement,
                                           argument: edge == .top ? "Scrolled to top" : "Scrolled to bottom")
                    }
                }

                // Floating Action Button at bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            bookToEdit = nil
                            showingAddBookSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel("Add new book")
                        .accessibilityHint("Double tap to open the book creation form")
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .task {
                await prefetchProfileData()
            }
            .sheet(isPresented: $showingAddBookSheet) {
                BookAddViewLibrarian(onSave: { newBook in
                    addNewBook(newBook)
                })
                .accessibilityLabel("Add new book form")
            }
            .sheet(isPresented: $isEditingBook) {
                BookDetailsStep(
                    bookData: $bookData,
                    showImagePicker: $showImagePicker,
                    isLoading: $isLoading,
                    onSave: {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            
                            let updatedBook = BookModel(
                                id: editingBookId ?? UUID(),
                                libraryId: bookData.libraryId ?? UUID(),
                                title: bookData.bookTitle,
                                isbn: bookData.isbn,
                                description: bookData.description,
                                totalCopies: bookData.totalCopies,
                                availableCopies: bookData.availableCopies,
                                reservedCopies: bookData.reservedCopies,
                                authorIds: bookData.authorIds,
                                authorNames: bookData.authorNames,
                                genreIds: bookData.genreIds,
                                genreNames: bookData.genreNames,
                                publishedDate: bookData.publishedDate,
                                coverImageUrl: bookData.bookCoverUrl,
                                coverImageData: bookData.bookCover?.jpegData(compressionQuality: 0.8)
                            )
                            
                            do {
                                let apiBook = try await updateBookAPI(book: updatedBook)
                                updateBook(apiBook)
                                isEditingBook = false
                                editingBookId = nil
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                )
                .accessibilityLabel("Edit book details")
            }
            .sheet(isPresented: $isShowingProfile) {
                Group {
                    if isPrefetchingProfile {
                        ProgressView("Loading Profile...")
                            .padding()
                            .accessibilityLabel("Loading profile information")
                    } else if let user = prefetchedUser, let library = prefetchedLibrary {
                        ProfileView(prefetchedUser: user, prefetchedLibrary: library)
                            .navigationBarItems(trailing: Button("Done") {
                                isShowingProfile = false
                            })
                            .accessibilityLabel("Profile information")
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                                .accessibilityHidden(true)
                            Text("Could Not Load Profile")
                                .font(.headline)
                            if let errorMsg = prefetchError {
                                Text(errorMsg)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            Button("Retry") {
                                Task { await prefetchProfileData() }
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Retry loading profile")
                        }
                        .padding()
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Librarian Home Screen")
            .task {
                await loadBooks()
                await prefetchProfileData()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // Helper to check if filtering is active
    var isFiltering: Bool {
        return !searchText.isEmpty || selectedCategory != .all
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome " + (prefetchedUser != nil ? prefetchedUser!.name : "loading..."))
                    .font(.headline)
                    .foregroundColor(Color.text(for: colorScheme))
                Text((prefetchedLibrary?.name ?? "loading..."))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Welcome \(prefetchedUser?.name ?? "user"), \(prefetchedLibrary?.name ?? "library")")

            Spacer()

            Button(action: { showProfileSheet = true }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color.primary(for: colorScheme).opacity(0.8))
            }
            .accessibilityLabel("User profile")
            .accessibilityHint("Double tap to view your profile information")
        }
        .task {
            await prefetchProfileData()
        }
        .padding(.horizontal)
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                if isPrefetchingProfile {
                    ProgressView("Loading Profile...")
                        .padding()
                        .accessibilityLabel("Loading profile information")
                } else if let user = prefetchedUser {
                    ProfileView()
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showProfileSheet = false
                            }
                            .accessibilityLabel("Done")
                        )
                        .accessibilityLabel("Profile information")
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("Could Not Load Profile")
                            .font(.headline)
                        if let errorMsg = prefetchError {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        Button("Retry") {
                            Task { await prefetchProfileData() }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Retry loading profile")
                    }
                    .padding()
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func loadBooks() async {
        isLoading = true
        fetchBooks(manager: homePaginationManager) { result in
            defer { isLoading = false }
            switch result {
            case let .success(fetchedBooks):
                self.books = fetchedBooks
                for book in fetchedBooks where book.coverImageUrl != nil {
                    self.preloadBookCover(for: book)
                }
                UIAccessibility.post(notification: .announcement, argument: "Books loaded successfully")
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                self.showError = true
                UIAccessibility.post(notification: .announcement, argument: "Failed to load books")
            }
        }
    }
    
    private func loadMoreBooks() {
        guard !isFiltering && !isLoadingMore else { return }
        
        isLoadingMore = true
        lms.loadMoreBooks(manager: homePaginationManager) { result in
            self.isLoadingMore = false
            
            switch result {
            case .success(let allBooks):
                withAnimation {
                    self.books = allBooks
                }
                print("[DEBUG] (HomeViewLibrarian) Loaded more books. Total count: \(allBooks.count)")
                UIAccessibility.post(notification: .announcement, argument: "Loaded more books")
            case .failure(let error):
                self.errorMessage = "Failed to load more books: \(error.localizedDescription)"
                self.showError = true
                print("[ERROR] (HomeViewLibrarian) Failed to load more books: \(error)")
                UIAccessibility.post(notification: .announcement, argument: "Failed to load more books")
            }
        }
    }

    private func preloadBookCover(for book: BookModel) {
        guard let urlString = book.coverImageUrl,
              let url = URL(string: urlString) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error preloading image for \(book.title): \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse,
               !(200 ... 299).contains(httpResponse.statusCode) {
                print("HTTP Error \(httpResponse.statusCode) preloading image for \(book.title)")
                return
            }
            if let data = data, UIImage(data: data) != nil {
                print("Successfully preloaded image for \(book.title)")
            } else {
                print("Invalid image data for \(book.title)")
            }
        }.resume()
    }

    private func deleteBook(_ book: BookModel) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            withAnimation {
                books.remove(at: index)
            }
            UIAccessibility.post(notification: .announcement, argument: "Book removed")
        }
    }

    private func addNewBook(_ book: BookModel) {
        withAnimation {
            books.append(book)
        }
        UIAccessibility.post(notification: .announcement, argument: "New book added")
    }
    
    private func updateBook(_ updatedBook: BookModel) {
        if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
            withAnimation {
                books[index] = updatedBook
            }
            UIAccessibility.post(notification: .announcement, argument: "Book updated")
        }
    }

    private func prefetchProfileData() async {
        guard !isPrefetchingProfile else { return }

        isPrefetchingProfile = true
        prefetchError = nil

        do {
            guard
                let currentUser = try await LoginManager.shared.getCurrentUser()
            else {
                throw NSError(
                    domain: "HomeView", code: 404,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No current user session found.",
                    ])
            }

            let libraryData = try await fetchLibraryData(
                libraryId: currentUser.library_id)

            await MainActor.run {
                self.prefetchedUser = currentUser
                self.prefetchedLibrary = libraryData
                self.isPrefetchingProfile = false
            }
        } catch {
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
            }
        }
    }

    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
              let url = URL(
                  string:
                  "https://www.anwinsharon.com/lms/api/v1/libraries/\(libraryId)"
              )
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(
                domain: "APIError", code: statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to fetch library data. Status code: \(statusCode)",
                ])
        }

        do {
            return try JSONDecoder().decode(Library.self, from: data)
        } catch {
            print("JSON Decoding Error for Library: \(error)")
            print(
                "Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")"
            )
            throw error
        }
    }
}

struct LibrarianViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeViewLibrarian()
                .preferredColorScheme(.light)
                .previewDisplayName("Home Light")
            HomeViewLibrarian()
                .preferredColorScheme(.dark)
                .previewDisplayName("Home Dark")
            UsersViewLibrarian()
                .preferredColorScheme(.light)
                .previewDisplayName("Users Light")
            RequestViewLibrarian()
                .preferredColorScheme(.light)
                .previewDisplayName("Manage Light")
        }
    }
}
