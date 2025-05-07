// CODE FOR NORMAL ADD BUTTON

// import Foundation
// import NavigationBarLargeTitleItems
// import SwiftUI
//
// struct HomeViewLibrarian: View {
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var isShowingProfile = false
//    @State private var prefetchedUser: User? = nil
//    @State private var prefetchedLibrary: Library?
//    @State private var isPrefetchingProfile = false
//    @State private var prefetchError: String? = nil
//
//    @State private var library: Library?
//    @State private var libraryName: String = "Infosys Library"
//
//    @State private var books: [BookModel] = []
//    @State private var searchText: String = ""
//    @State private var selectedCategory: BookGenre = .all
//    @State private var showingAddBookSheet = false
//    @State private var bookToEdit: BookModel?
//    @State private var bookData = BookData()
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//    @State private var showError = false
//
//    init(prefetchedUser: User? = nil, prefetchedLibrary: Library? = nil) {
//        self.prefetchedUser = prefetchedUser
//        self.prefetchedLibrary = prefetchedLibrary
//        self.library = prefetchedLibrary
//
//        // Try to get library name from keychain
//        if let name = try? KeychainManager.shared.getLibraryName() {
//            _libraryName = State(initialValue: name)
//        }
//    }
//
//    var filteredBooks: [BookModel] {
//        var result = books
//        if selectedCategory != .all {
//            result = result.filter { $0.genreNames?.contains(selectedCategory.rawValue) == true }
//        }
//        if !searchText.isEmpty {
//            result = result.filter { book in
//                book.title.localizedCaseInsensitiveContains(searchText) ||
//                (book.isbn ?? "").localizedCaseInsensitiveContains(searchText)
//            }
//        }
//        return result
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme)
//                VStack(spacing: 0) {
//                    // Custom header with "Infosys Library" title and buttons
//                    HStack {
//                        Text(libraryName)
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .foregroundColor(.black) // Fixed black color
//                        Spacer()
//                        HStack(spacing: 16) {
//                            Button(action: {
//                                bookToEdit = nil
//                                showingAddBookSheet = true
//                            }) {
//                                Image(systemName: "plus")
//                                    .font(.title2)
//                                    .foregroundColor(Color.primary(for: colorScheme))
//                            }
//                            Button(action: {
//                                isShowingProfile = true
//                            }) {
//                                Image(systemName: "person.circle.fill")
//                                    .resizable()
//                                    .frame(width: 36, height: 36)
//                                    .foregroundColor(.red)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.top, 10)
//                    .padding(.bottom, 8)
//
//                    ScrollView {
//                        VStack(spacing: 16) {
//                            SearchBar(searchText: $searchText, colorScheme: colorScheme)
//                            CategoryFilterView(
//                                selectedCategory: $selectedCategory,
//                                colorScheme: colorScheme
//                            )
//                            if isLoading {
//                                LoadingAnimationView(colorScheme: colorScheme)
//                            } else {
//                                if books.isEmpty {
//                                    EmptyBookListView(colorScheme: colorScheme)
//                                } else {
//                                    BookList(
//                                        books: filteredBooks,
//                                        colorScheme: colorScheme,
//                                        onEdit: { book in
//                                            bookToEdit = book
//                                            showingAddBookSheet = true
//                                        },
//                                        onDelete: deleteBook
//                                    )
//                                }
//                            }
//                        }
//                        .padding(.top)
//                    }
//                    .refreshable {
//                        await loadBooks()
//                    }
//                }
//            }
//            .task {
//                await prefetchProfileData()
//            }
//            .sheet(isPresented: $showingAddBookSheet) {
//                if let bookToEdit = bookToEdit {
//                    Text("Edit Book")
//                        .font(.headline)
//                        .padding()
//                } else {
//                    BookAddViewAdmin(onSave: { newBook in
//                        addNewBook(newBook)
//                    })
//                }
//            }
//            .sheet(isPresented: $isShowingProfile) {
//                Group {
//                    if isPrefetchingProfile {
//                        ProgressView("Loading Profile...")
//                            .padding()
//                    } else if let user = prefetchedUser, let library = prefetchedLibrary {
//                        ProfileView(prefetchedUser: user, prefetchedLibrary: library)
//                            .navigationBarItems(trailing: Button("Done") {
//                                isShowingProfile = false
//                            })
//                    } else {
//                        VStack(spacing: 16) {
//                            Image(systemName: "exclamationmark.triangle.fill")
//                                .font(.largeTitle)
//                                .foregroundColor(.orange)
//                            Text("Could Not Load Profile")
//                                .font(.headline)
//                            if let errorMsg = prefetchError {
//                                Text(errorMsg)
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                                    .multilineTextAlignment(.center)
//                            }
//                            Button("Retry") {
//                                Task { await prefetchProfileData() }
//                            }
//                            .buttonStyle(.borderedProminent)
//                        }
//                        .padding()
//                    }
//                }
//            }
//            .alert("Error", isPresented: $showError) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(errorMessage ?? "An unknown error occurred")
//            }
//            .task {
//                await loadBooks()
//                await prefetchProfileData()
//            }
//        }
//    }
//
//    private func loadBooks() async {
//        isLoading = true
//        fetchBooks { result in
//            defer { isLoading = false }
//            switch result {
//            case let .success(fetchedBooks):
//                self.books = fetchedBooks
//                for book in fetchedBooks where book.coverImageUrl != nil {
//                    self.preloadBookCover(for: book)
//                }
//            case let .failure(error):
//                self.errorMessage = error.localizedDescription
//                self.showError = true
//            }
//        }
//    }
//
//    private func preloadBookCover(for book: BookModel) {
//        guard let urlString = book.coverImageUrl,
//              let url = URL(string: urlString) else {
//            return
//        }
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error preloading image for \(book.title): \(error.localizedDescription)")
//                return
//            }
//            if let httpResponse = response as? HTTPURLResponse,
//               !(200...299).contains(httpResponse.statusCode) {
//                print("HTTP Error \(httpResponse.statusCode) preloading image for \(book.title)")
//                return
//            }
//            if let data = data, UIImage(data: data) != nil {
//                print("Successfully preloaded image for \(book.title)")
//            } else {
//                print("Invalid image data for \(book.title)")
//            }
//        }.resume()
//    }
//
//    private func deleteBook(_ book: BookModel) {
//        if let index = books.firstIndex(where: { $0.id == book.id }) {
//            withAnimation {
//                books.remove(at: index)
//            }
//        }
//    }
//
//    private func addNewBook(_ book: BookModel) {
//        withAnimation {
//            books.append(book)
//        }
//    }
//
//    private func prefetchProfileData() async {
//        guard !isPrefetchingProfile else { return }
//
//        isPrefetchingProfile = true
//        prefetchError = nil
//
//        do {
//            guard
//                let currentUser = try await LoginManager.shared.getCurrentUser()
//            else {
//                throw NSError(
//                    domain: "HomeView", code: 404,
//                    userInfo: [
//                        NSLocalizedDescriptionKey:
//                            "No current user session found."
//                    ])
//            }
//
//            let libraryData = try await fetchLibraryData(
//                libraryId: currentUser.library_id)
//
//            await MainActor.run {
//                self.prefetchedUser = currentUser
//                self.prefetchedLibrary = libraryData
//                self.isPrefetchingProfile = false
//            }
//        } catch {
//            await MainActor.run {
//                self.prefetchError = error.localizedDescription
//                self.isPrefetchingProfile = false
//                self.prefetchedUser = nil
//                self.prefetchedLibrary = nil
//            }
//        }
//    }
//
//    private func fetchLibraryData(libraryId: String) async throws -> Library {
//        guard let token = try? LoginManager.shared.getCurrentToken(),
//            let url = URL(
//                string:
//                    "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)"
//            )
//        else {
//            throw URLError(.badURL)
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//            httpResponse.statusCode == 200
//        else {
//            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
//            throw NSError(
//                domain: "APIError", code: statusCode,
//                userInfo: [
//                    NSLocalizedDescriptionKey:
//                        "Failed to fetch library data. Status code: \(statusCode)"
//                ])
//        }
//
//        do {
//            return try JSONDecoder().decode(Library.self, from: data)
//        } catch {
//            print("JSON Decoding Error for Library: \(error)")
//            print(
//                "Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")"
//            )
//            throw error
//        }
//    }
// }
//
// struct LibrarianViews_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            HomeViewLibrarian()
//                .preferredColorScheme(.light)
//                .previewDisplayName("Home Light")
//            HomeViewLibrarian()
//                .preferredColorScheme(.dark)
//                .previewDisplayName("Home Dark")
//            UsersViewLibrarian()
//                .preferredColorScheme(.light)
//                .previewDisplayName("Users Light")
//            RequestViewLibrarian()
//                .preferredColorScheme(.light)
//                .previewDisplayName("Manage Light")
//        }
//    }
// }

// CODE WITH FLOATING ADD BUTTON

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
                VStack(spacing: 0) {
                    headerSection
                        .padding(.bottom, 12)

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
                                    )                            }
                            }
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        await loadBooks()
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
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .task {
                await prefetchProfileData()
            }
//            .sheet(isPresented: $showingAddBookSheet) {
//                NavigationView {
//                    if let book = bookToEdit {
//                        // Use the same BookAddViewAdmin but pass the book to edit
//                        BookAddViewAdmin(bookToEdit: book, onSave: { updatedBook in
//                            updateBook(updatedBook)
//                        })
//                        .navigationTitle("Edit Book")
//                        .navigationBarItems(trailing: Button("Cancel") {
//                            showingAddBookSheet = false
//                        })
//                    } else {
//                        BookAddViewAdmin(onSave: { newBook in
//                            addNewBook(newBook)
//                        })
//                        .navigationTitle("Add New Book")
//                        .navigationBarItems(trailing: Button("Cancel") {
//                            showingAddBookSheet = false
//                        })
//                    }
//                }
//            }
            .sheet(isPresented: $showingAddBookSheet) {
                BookAddViewLibrarian(onSave: { newBook in
                    addNewBook(newBook)
                })
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

            Spacer()

            Button(action: { showProfileSheet = true }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(
                        Color.primary(for: colorScheme).opacity(0.8))
            }
        }
        .task{
            await prefetchProfileData()
        }
        .padding(.horizontal)
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                if isPrefetchingProfile {
                    ProgressView("Loading Profile...")
                        .padding()
                } else if let user = prefetchedUser {
                    ProfileView()
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showProfileSheet = false
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
        }
    }

    private func addNewBook(_ book: BookModel) {
        withAnimation {
            books.append(book)
        }
    }
    
    private func updateBook(_ updatedBook: BookModel) {
        if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
            withAnimation {
                books[index] = updatedBook
            }
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
                  "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)"
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
