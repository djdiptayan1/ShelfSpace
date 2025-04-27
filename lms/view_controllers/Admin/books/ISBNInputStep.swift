//
//  File.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI
import UIKit

struct BookData {
    var isbn: String
    var bookInfo: BookInfo?
    var bookCover: UIImage?
    
    var bookTitle: String
    var description: String
    var totalCopies: Int
    var availableCopies: Int
    var reservedCopies: Int
    
    var authorNames: [String] = [] // For UI input
    var genreNames: [String] = []
    
    var publishedDate: Date
    var authorIds: [UUID]            // ✅ Added to match DB
    var genreIds: [UUID]             // ✅ Already present
    var libraryId: UUID?             // ✅ Added to match DB
    
    var publisher: String
    var pageCount: String
    var language: String
    var categories: [String]
    
    init(isbn: String = "") {
        self.isbn = isbn
        self.bookInfo = nil
        self.bookCover = nil
        
        self.bookTitle = ""
        self.description = ""
        self.totalCopies = 1
        self.availableCopies = 1
        self.reservedCopies = 0
        
        self.publishedDate = Date()
        self.authorNames = []
        self.authorIds = []
        self.genreIds = []
        self.libraryId = nil
        
        self.publisher = ""
        self.pageCount = ""
        self.language = ""
        self.categories = []
    }
}

struct ISBNInputStep: View {
    @Binding var bookData: BookData
    @Binding var showBarcodeScanner: Bool
    let onContinue: () -> Void
    let onScanComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isISBNFocused: Bool
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let bookInfoService = BookInfoService()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add a Book")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.text(for: colorScheme))
                .padding(.top, 30)
            
            Text("Enter the ISBN number to identify the book")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // ISBN Input Card
            VStack(spacing: 20) {
                // Manual Input Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                        
                        Text("Manual Entry")
                            .font(.headline)
                            .foregroundColor(Color.text(for: colorScheme))
                    }
                    .padding(.bottom, 4)
                    
                    HStack {
                        TextField("Enter ISBN number", text: $bookData.isbn)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .focused($isISBNFocused)
                            .onChange(of: bookData.isbn) { newValue in
                                // Remove any non-digit characters
                                bookData.isbn = newValue.filter { $0.isNumber }
                                
                                // Limit to 13 digits
                                if bookData.isbn.count > 13 {
                                    bookData.isbn = String(bookData.isbn.prefix(13))
                                }
                            }
                        
                        Button(action: {
                            bookData.isbn = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .opacity(bookData.isbn.isEmpty ? 0 : 1)
                        }
                        .disabled(bookData.isbn.isEmpty)
                    }
                    
                    Text("Enter the 13-digit ISBN number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Text("OR")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Barcode Scanner Card
                Button(action: {
                    showBarcodeScanner = true
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            
                            Text("Scan Barcode")
                                .font(.headline)
                                .foregroundColor(Color.text(for: colorScheme))
                        }
                        .padding(.bottom, 4)
                        
                        HStack {
                            Spacer()
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )
                            
                            Spacer()
                        }
                        
                        Text("Scan the book's barcode using your camera")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                Task {
                    await fetchBookInfo()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    bookData.isbn.isEmpty || isLoading ?
                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.3)]), startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .disabled(bookData.isbn.isEmpty || isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .opacity(bookData.isbn.isEmpty || isLoading ? 0.6 : 1.0)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView(scannedCode: $bookData.isbn, onScanComplete: { code in
                Task {
                    await fetchBookInfo()
                    onScanComplete()
                }
            })
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isISBNFocused = true
            }
        }
    }
    
    private func fetchBookInfo() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔍 Fetching book info for ISBN: \(bookData.isbn)")
            if let info = try await bookInfoService.fetchBookInfo(isbn: bookData.isbn) {
                // Debug print the fetched book info
                print("\n📚 Fetched Book Details:")
                print("Title: \(info.title)")
                print("Authors: \(info.authors.joined(separator: ", "))")
                print("Publisher: \(info.publisher ?? "N/A")")
                print("Published Date: \(info.publishedDate ?? "N/A")")
                print("Description: \(info.description ?? "N/A")")
                print("Page Count: \(info.pageCount.map { String($0) } ?? "N/A")")
                print("Language: \(info.language ?? "N/A")")
                print("Categories: \(info.categories?.joined(separator: ", ") ?? "N/A")")
                if let identifiers = info.industryIdentifiers {
                    print("ISBNs:")
                    for identifier in identifiers {
                        print("- \(identifier.type): \(identifier.identifier)")
                    }
                }
                
                // Update book data with fetched info
                bookData.bookInfo = info
                bookData.bookTitle = info.title
                bookData.description = info.description ?? ""
                bookData.authorNames = info.authors
                bookData.publisher = info.publisher ?? ""
                bookData.pageCount = info.pageCount.map { String($0) } ?? ""
                bookData.language = info.language ?? ""
                bookData.categories = info.categories ?? []
                
                if let dateString = info.publishedDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: dateString) {
                        bookData.publishedDate = date
                    }
                }
                
                // Try to load book cover from Google Books first
                if let thumbnailURL = info.imageLinks?.thumbnail {
                    print("\n📸 Loading book cover from Google Books: \(thumbnailURL)")
                    bookData.bookCover = try await bookInfoService.loadImage(from: thumbnailURL)
                    print("✅ Book cover loaded successfully from Google Books")
                }
                
                // If no cover from Google Books, try OpenLibrary
                if bookData.bookCover == nil {
                    print("\n📸 Trying to load book cover from OpenLibrary")
                    // Try both ISBN-10 and ISBN-13 if available
                    if let identifiers = info.industryIdentifiers {
                        for identifier in identifiers {
                            if identifier.type == "ISBN_10" || identifier.type == "ISBN_13" {
                                if let cover = try await bookInfoService.loadCoverFromOpenLibrary(isbn: identifier.identifier) {
                                    bookData.bookCover = cover
                                    print("✅ Book cover loaded successfully from OpenLibrary")
                                    break
                                }
                            }
                        }
                    }
                }
                
                if bookData.bookCover == nil {
                    print("\n⚠️ No book cover available from any source")
                }
                
                onContinue()
            } else {
                print("\n⚠️ No book found with ISBN: \(bookData.isbn)")
                // Show warning but allow to proceed
                showError = true
                errorMessage = "No book found with this ISBN. You can still proceed to add the book manually."
                onContinue()
            }
        } catch {
            showError = true
            errorMessage = "Failed to fetch book information: \(error.localizedDescription)"
            print("\n❌ Error fetching book info: \(error)")
            // Still allow to proceed even if there's an error
            onContinue()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var bookData = BookData()
        @State private var showBarcodeScanner = false
        
        var body: some View {
            ISBNInputStep(
                bookData: $bookData,
                showBarcodeScanner: $showBarcodeScanner,
                onContinue: {},
                onScanComplete: {}
            )
        }
    }
    
    return PreviewWrapper()
}
