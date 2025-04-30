import Foundation
import NavigationBarLargeTitleItems
import SwiftUI

struct HomeViewLibrarian: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingProfile = false
    @State private var prefetchedUser: User? = nil
    @State private var prefetchedLibrary: Library? = nil
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    
    @State private var books: [BookModel] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: BookGenre = .all
    @State private var showingAddBookSheet = false
    @State private var bookToEdit: BookModel?
    @State private var bookData = BookData()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

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
                ScrollView {
                    VStack(spacing: 16) {
                        SearchBar(searchText: $searchText, colorScheme: colorScheme)
                        CategoryFilterView(
                            selectedCategory: $selectedCategory,
                            colorScheme: colorScheme
                        )
                        if isLoading {
                            LoadingAnimationView(colorScheme: colorScheme)
                        } else {
                            if books.isEmpty {
                                EmptyBookListView(colorScheme: colorScheme)
                            } else {
                                BookList(
                                    books: filteredBooks,
                                    colorScheme: colorScheme,
                                    onEdit: { book in
                                        bookToEdit = book
                                        showingAddBookSheet = true
                                    },
                                    onDelete: deleteBook
                                )
                            }
                        }
                    }
                    .padding(.top)
                }
                .refreshable {
                    await loadBooks()
                }
            }
            .navigationTitle("My Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            bookToEdit = nil
                            showingAddBookSheet = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.primary(for: colorScheme))
                        }
                        Button(action: {
                            isShowingProfile = true
                        }) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddBookSheet) {
                if let bookToEdit = bookToEdit {
                    Text("Edit Book")
                        .font(.headline)
                        .padding()
                } else {
                    BookAddViewAdmin(onSave: { newBook in
                        addNewBook(newBook)
                    })
                }
            }
            .sheet(isPresented: $isShowingProfile) {
                Group {
                    if isPrefetchingProfile {
                        ProgressView("Loading Profile...")
                            .padding()
                    } else if let user = prefetchedUser, let library = prefetchedLibrary {
                        ProfileView(prefetchedUser: user, prefetchedLibrary: library)
                            .navigationBarItems(trailing: Button("Done") {
                                isShowingProfile = false
                            })
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
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
                        }
                        .padding()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                await loadBooks()
                await prefetchProfileData()
            }
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        fetchBooks { result in
            defer { isLoading = false }
            switch result {
            case let .success(fetchedBooks):
                self.books = fetchedBooks
                for book in fetchedBooks where book.coverImageUrl != nil {
                    self.preloadBookCover(for: book)
                }
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                self.showError = true
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
               !(200...299).contains(httpResponse.statusCode) {
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
        }
    }
    
    private func addNewBook(_ book: BookModel) {
        withAnimation {
            books.append(book)
        }
    }
    
    private func prefetchProfileData() async {
        guard !isPrefetchingProfile else { return }
        isPrefetchingProfile = true
        prefetchError = nil
        print("Prefetching profile data...")
        do {
            if let cachedUser = UserCacheManager.shared.getCachedUser() {
                print("Using cached user data")
                let libraryData = try await fetchLibraryData(libraryId: cachedUser.library_id)
                await MainActor.run {
                    self.prefetchedUser = cachedUser
                    self.prefetchedLibrary = libraryData
                    self.isPrefetchingProfile = false
                }
                return
            }
            guard let currentUser = try await LoginManager.shared.getCurrentUser() else {
                throw NSError(domain: "HomeViewLibrarian", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user session found."])
            }
            let libraryData = try await fetchLibraryData(libraryId: currentUser.library_id)
            await MainActor.run {
                self.prefetchedUser = currentUser
                self.prefetchedLibrary = libraryData
                self.isPrefetchingProfile = false
                print("Profile data prefetched successfully.")
            }
        } catch {
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
                print("Error prefetching profile data: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
              let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "APIError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)"])
        }
        do {
            return try JSONDecoder().decode(Library.self, from: data)
        } catch {
            print("JSON Decoding Error for Library: \(error)")
            print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
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
            ManageViewLibrarian()
                .preferredColorScheme(.light)
                .previewDisplayName("Manage Light")
        }
    }
}
