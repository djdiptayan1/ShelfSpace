//
//  BookViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//
import DotLottie
import Foundation
import SwiftUI

struct BookViewAdmin: View {
    @StateObject private var homePaginationManager = BookPaginationManager()
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var books: [BookModel] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: BookGenre = .all
    @State private var showingAddBookSheet = false
    @State private var bookToEdit: BookModel?
    @State private var showAddBook = false
    @State private var showImagePicker = false

    @State private var bookData = BookData()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isEditingBook = false
    @State private var editingBookId: UUID? = nil
    @State private var isLoadingMore = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil

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

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Search bar (scrolls with content)
                            SearchBar(searchText: $searchText, colorScheme: colorScheme)

                            // Category filter (scrolls with content)
                            CategoryFilterView(
                                selectedCategory: $selectedCategory,
                                colorScheme: colorScheme
                            )

                            // Loading or Book List (scrolls below search & filter)
                            if isLoading {
                                LoadingAnimationView(colorScheme: colorScheme)
                                    .padding(.top, 100)

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
                                    )
                                    
                                    // Bottom loader for pagination
                                    if !filteredBooks.isEmpty {
                                        HStack {
                                            Spacer()
                                            if isLoadingMore {
                                                ProgressView()
                                                    .padding()
                                            }
                                            Spacer()
                                        }
                                        .id("BottomLoader")
                                        .onAppear {
                                            // When this appears, load more content if needed
                                            if !searchText.isEmpty || selectedCategory != .all {
                                                // Don't load more when filtering
                                                return
                                            }
                                            loadMoreBooks()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                    .refreshable {
                        await loadBooks()
                    }
                }
            }
            .navigationTitle("Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        bookToEdit = nil
                        showingAddBookSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.primary(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showingAddBookSheet) {
                BookAddViewAdmin(onSave: { newBook in
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                await loadBooks()
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
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func loadMoreBooks() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        // Remove the [weak self] capture list since structs don't need weak references
        // And fix the explicit type annotation
        lms.loadMoreBooks(manager: homePaginationManager) { result in
            self.isLoadingMore = false
            switch result {
            case .success(let allBooks):
                withAnimation {
                    self.books = allBooks
                }
                print("[DEBUG] (BookViewAdmin) Loaded more books. Total count: \(allBooks.count)")
            case .failure(let error):
                self.errorMessage = "Failed to load more books: \(error.localizedDescription)"
                self.showError = true
                print("[ERROR] (BookViewAdmin) Failed to load more books: \(error)")
            }
        }
    }
    
    private func preloadBookCover(for book: BookModel) {
        guard let urlString = book.coverImageUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Log for debugging
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
                // In a real application, you might want to store this in a cache
            } else {
                print("Invalid image data for \(book.title)")
            }
        }.resume()
    }

    private func deleteBook(_ book: BookModel) {
        Task {
            do {
                try await deleteBookAPI(bookId: book.id)
                if let index = books.firstIndex(where: { $0.id == book.id }) {
                    withAnimation {
                        books.remove(at: index)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
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
}
struct LoadingAnimationView: View {
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            DotLottieAnimation(
                fileName: "loading",
                config: AnimationConfig(
                    autoplay: true,
                    loop: true,
                    mode: .bounce,
                    speed: 1.0
                )
            )
            .view()
            .padding(.top, 40)
            .frame(height: 100)
        }
    }
}
// Empty state view for when there are no books
struct EmptyBookListView: View {
    var colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color.primary(for: colorScheme).opacity(0.7))
                .padding(.bottom, 10)

            Text("No books found")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add new books using the + button or pull down to refresh")
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Subviews

struct SearchBar: View {
    @Binding var searchText: String
    var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.primary(for: colorScheme).opacity(0.8))
                .padding(.leading, 12)

            TextField("Search books...", text: $searchText)
                .padding(.vertical, 12)
                .font(.system(size: 16, design: .rounded))

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.primary(for: colorScheme).opacity(0.9))
                }
                .padding(.trailing, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: ColorConstants.darkBackground) : Color(hex: ColorConstants.lightBackground))
        )
        .padding(.horizontal)
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: BookGenre
    var colorScheme: ColorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BookGenre.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        selectedCategory: $selectedCategory,
                        colorScheme: colorScheme
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    var category: BookGenre
    @Binding var selectedCategory: BookGenre
    var colorScheme: ColorScheme

    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedCategory = category
            }
        }) {
            Text(category.rawValue)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedCategory == category ?
                            (colorScheme == .dark ? Color.primary(for: colorScheme).opacity(0.3) : Color.secondary(for: colorScheme).opacity(0.15)) :
                            (colorScheme == .dark ? Color(hex: ColorConstants.darkBackground1) : Color(hex: ColorConstants.lightBackground1)))
                )
                .overlay(
                    Capsule()
                        .stroke(selectedCategory == category ? Color.background(for: colorScheme).opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .foregroundColor(selectedCategory == category ?
            (colorScheme == .dark ? .white : Color.secondary(for: colorScheme)) :
            Color.text(for: colorScheme).opacity(0.7))
    }
}

struct BookList: View {
    var books: [BookModel]
    var colorScheme: ColorScheme
    var onEdit: (BookModel) -> Void
    var onDelete: (BookModel) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(books) { book in
                BookCell(
                    book: book,
                    onEdit: { onEdit(book) },
                    onDelete: { onDelete(book) }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct BookCell: View {
    var book: BookModel
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        ZStack {
            BooksCell(book: book)

            // Invisible button covering the entire cell to handle taps
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Handle tap action if needed
                }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// Scroll offset preference key to track scrolling
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct BookViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        BookViewAdmin()
            .preferredColorScheme(.light)

        BookViewAdmin()
            .preferredColorScheme(.dark)
    }
}
