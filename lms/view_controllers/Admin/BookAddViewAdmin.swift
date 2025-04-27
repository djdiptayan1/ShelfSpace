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
                
                switch currentStep {
                case .isbn:
                    ISBNInputStep(
                        bookData: $bookData,
                        showBarcodeScanner: $showBarcodeScanner,
                        onContinue: {
                            withAnimation(.easeInOut) {
                                currentStep = .details
                            }
                        },
                        onScanComplete: {
                            withAnimation(.easeInOut) {
                                currentStep = .details
                            }
                        }
                    )
                case .details:
                    BookDetailsStep(
                        bookData: $bookData,
                        showImagePicker: $showImagePicker,
                        onSave: {
                            saveBook()
                            dismiss()
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
                BarcodeScannerView(scannedCode: $bookData.isbn) { _ in
                    // This will be handled by the ISBNInputStep's onScanComplete
                    // We don't need to do anything here because the ISBNInputStep
                    // will automatically trigger the navigation when it receives the scanned code
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
            authorIds: authorIds,
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
}

#Preview {
    BookAddViewAdmin(onSave: { _ in })
}
