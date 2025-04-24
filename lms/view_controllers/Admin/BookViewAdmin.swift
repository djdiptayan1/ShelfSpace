//
//  BookViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//
import Foundation
import SwiftUI

struct BookViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme
     @State private var books: [BookModel] = demoBooks
//    @State private var books: [BookModel] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: BookCategory = .all
    @State private var showingAddBookSheet = false
    @State private var bookToEdit: BookModel?
    @State private var showAddBook = false

        @State private var showImagePicker = false

    @State private var bookData = BookData()

    enum BookCategory: String, CaseIterable {
        case all = "All"
        case comedy = "Comedy"
        case thriller = "Thriller"
        case romantic = "Romantic"
        case horror = "Horror"
    }

    var filteredBooks: [BookModel] {
        var result = books

        if selectedCategory != .all {
            result = result.filter { _ in
                true // Replace with actual genre filtering
            }
        }

        if !searchText.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                    book.authorNames.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
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
                    .padding(.top)
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
        }
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
    @Binding var selectedCategory: BookViewAdmin.BookCategory
    var colorScheme: ColorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BookViewAdmin.BookCategory.allCases, id: \.self) { category in
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
    var category: BookViewAdmin.BookCategory
    @Binding var selectedCategory: BookViewAdmin.BookCategory
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
