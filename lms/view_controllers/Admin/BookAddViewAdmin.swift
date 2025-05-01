//
//  BookAddViewAdmin.swift
//  lms
//
//  Created by dark on 23/04/25.
//

import SwiftUI

struct BookAddViewAdmin: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: BookAddStep = .isbn
    @State private var showImagePicker = false
    @State private var showBarcodeScanner = false
    @State private var bookData = BookData()
    @State private var focusedField: BookFieldType?
    @State private var isLoading = false
    var bookToEdit: BookModel? = nil
    var onSave: (BookModel) -> Void
    
    enum BookAddStep {
        case isbn
        case details
    }
    
    enum BookFieldType {
        case isbn
        case title
        case description
        case publisher
        case language
        case author
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                // Prefill bookData if editing
                Color.clear.onAppear {
                    if let book = bookToEdit {
                        bookData = BookAddViewAdmin.bookData(from: book)
                        if currentStep != .details {
                            currentStep = .details // Always jump to details step for editing
                        }
                    } else {
                        if currentStep != .isbn {
                            currentStep = .isbn // Always start at ISBN for adding
                        }
                    }
                }
                
                switch currentStep {
                case .isbn:
                    ISBNInputStep(
                        bookData: $bookData,
                        showBarcodeScanner: $showBarcodeScanner,
                        onContinue: {
                            withAnimation(.easeInOut) {
                                currentStep = .details
                            }
                        }, onScanComplete: {
                            withAnimation(.easeInOut) {
                                currentStep = .details
                            }
                        }
                    )
                case .details:
                    BookDetailsStep(
                        bookData: $bookData,
                        showImagePicker: $showImagePicker,
                        isLoading: $isLoading,
                        onSave: {
                            Task {
                                isLoading = true
                                defer { isLoading = false }
                                do {
                                    let bookModel = BookModel(
                                        id: UUID(),
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
                                        publishedDate: bookData.publishedDate,
                                        addedOn: Date(),
                                        updatedAt: Date(),
                                        coverImageUrl: bookData.bookCoverUrl,
                                        coverImageData: bookData.bookCover?.jpegData(compressionQuality: 0.8)
                                    )
                                    let createdBook = try await createBook(book: bookModel)
                                    print("✅ Book saved to database with ID: \(createdBook.id)")
                                    onSave(createdBook)
                                    dismiss()
                                } catch {
                                    print("❌ Error saving book: \(error)")
                                    // Optionally show error UI
                                }
                            }
                        }
                    )
                }
            }
            .navigationBarTitle(currentStep == .isbn ? "Add Book" : "Book Details", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    if currentStep == .details {
                        withAnimation(.easeInOut) {
                            currentStep = .isbn
                        }
                    } else {
                        dismiss()
                    }
                }) {
                    Text(currentStep == .details ? "Back" : "Cancel")
                        .foregroundColor(currentStep == .details ? .blue : .red)
                },
                trailing: currentStep == .details ?
                    Button(action: {
                        saveBook()
                        dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.medium)
                    } : nil
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $bookData.bookCover)
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(scannedCode: $bookData.isbn){_ in
                }
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    private func saveBook() {
        // Generate UUIDs for authors
        let authorIds = bookData.authorNames.map { _ in UUID() }
        
        // Convert UIImage to Data if available
        let coverImageData = bookData.bookCover?.jpegData(compressionQuality: 0.8)
        
        // TODO: In a real app, you would upload the image to cloud storage here
        // and get back the URL. For now, we'll just use a placeholder URL if we have an image
        let coverImageUrl = coverImageData != nil ? "https://placeholder-url.com/book-cover.jpg" : nil
        
        let newBook = BookModel(
            id: UUID(),
            libraryId: bookData.libraryId ?? UUID(), // Replace with real libraryId if you have it
            title: bookData.bookTitle,
            isbn: bookData.isbn,
            description: bookData.description,
            totalCopies: bookData.totalCopies,
            availableCopies: bookData.availableCopies,
            reservedCopies: bookData.reservedCopies,
            authorIds: bookData.authorIds,
            authorNames: bookData.authorNames,
            genreIds: bookData.genreIds,
            publishedDate: bookData.publishedDate,
            addedOn: Date(),
            updatedAt: Date(),
            coverImageUrl: coverImageUrl,
            coverImageData: coverImageData
        )

        
        // Call the onSave closure with the new book
        onSave(newBook)
    }
    
    // Helper to convert BookModel to BookData
    static func bookData(from model: BookModel) -> BookData {
        var data = BookData()
        data.id = model.id
        data.libraryId = model.libraryId
        data.isbn = model.isbn ?? ""
        data.bookTitle = model.title
        data.description = model.description ?? ""
        data.totalCopies = model.totalCopies
        data.availableCopies = model.availableCopies
        data.reservedCopies = model.reservedCopies
        data.authorNames = model.authorNames ?? []
        data.authorIds = model.authorIds
        data.genreNames = model.genreNames ?? []
        data.genreIds = model.genreIds
        data.publishedDate = model.publishedDate ?? Date()
        data.libraryId = model.libraryId
        data.bookCoverUrl = model.coverImageUrl
        data.categories = model.genreNames ?? []
        if let coverData = model.coverImageData {
            data.bookCover = UIImage(data: coverData)
        }
        return data
    }
}

#Preview {
    BookAddViewAdmin(onSave: { _ in })
}
