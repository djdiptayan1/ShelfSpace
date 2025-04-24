////
////  BookAddViewAdmin.swift
////  lms
////
////  Created by dark on 23/04/25.
////
//import SwiftUI
//
//struct BookAddViewAdmin: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var currentStep: BookAddStep = .isbn
//    @State private var isbn = ""
//    @State private var bookTitle = ""
//    @State private var description = ""
//    @State private var totalCopies = 1
//    @State private var publishedDate = Date()
//    @State private var showImagePicker = false
//    @State private var bookCover: UIImage?
//    
//    // New fields for testing
//    @State private var authorNames: [String] = [""]
//    @State private var genreIds: [UUID] = []
//    @State private var availableCopies = 1
//    @State private var reservedCopies = 0
//    @State private var authorIds: [UUID] = []
//    
//    enum BookAddStep {
//        case isbn
//        case details
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme)
//                
//                switch currentStep {
//                case .isbn:
//                    ISBNInputStep(isbn: $isbn, onContinue: {
//                        withAnimation(.easeInOut) {
//                            currentStep = .details
//                        }
//                    })
//                case .details:
//                    BookDetailsStep(
//                        isbn: isbn,
//                        bookTitle: $bookTitle,
//                        description: $description,
//                        totalCopies: $totalCopies,
//                        availableCopies: $availableCopies,
//                        reservedCopies: $reservedCopies,
//                        publishedDate: $publishedDate,
//                        authorNames: $authorNames,
//                        genreIds: $genreIds,
//                        bookCover: $bookCover,
//                        showImagePicker: $showImagePicker,
//                        onSave: {
//                            saveBook()
//                            dismiss()
//                        }
//                    )
//                }
//            }
//            .navigationBarTitle(currentStep == .isbn ? "Add Book" : "Book Details", displayMode: .inline)
//            .navigationBarItems(
//                leading: Button(action: {
//                    if currentStep == .details {
//                        withAnimation(.easeInOut) {
//                            currentStep = .isbn
//                        }
//                    } else {
//                        dismiss()
//                    }
//                }) {
//                        Text(currentStep == .details ? "Back" : "Cancel")
//                    .foregroundColor(currentStep == .details ? .blue : .red)
//                },
//                trailing: currentStep == .details ?
//                    Button(action: {
//                        saveBook()
//                        dismiss()
//                    }) {
//                        Text("Save")
//                            .fontWeight(.medium)
//                    } : nil
//            )
//            .sheet(isPresented: $showImagePicker) {
//                ImagePicker(image: $bookCover)
//            }
//        }
//    }
//    
//    private func saveBook() {
//        // Generate UUIDs for authors
//        authorIds = authorNames.map { _ in UUID() }
//        
//        let newBook = BookModel(
//            id: UUID(),
//            libraryId: UUID(), // You'll need to get the actual library ID
//            title: bookTitle,
//            isbn: isbn,
//            description: description,
//            totalCopies: totalCopies,
//            availableCopies: availableCopies,
//            reservedCopies: reservedCopies,
//            authorIds: authorIds,
//            authorNames: authorNames,
//            genreIds: genreIds,
//            publishedDate: publishedDate,
//            addedOn: Date()
//        )
//        // Save book implementation would go here
//    }
//}
//
//struct ISBNInputStep: View {
//    @Binding var isbn: String
//    let onContinue: () -> Void
//    @Environment(\.colorScheme) private var colorScheme
//    @FocusState private var isISBNFocused: Bool
//    
//    var body: some View {
//        VStack(spacing: 24) {
//            // ISBN Input Card
//            VStack(alignment: .leading, spacing: 8) {
//                Text("ISBN")
//                    .font(.headline)
//                    .foregroundColor(Color.text(for: colorScheme))
//                    .padding(.leading, 4)
//                
//                HStack {
//                    Image(systemName: "barcode")
//                        .foregroundColor(.blue)
//                        .font(.system(size: 18))
//                        .padding(.leading, 12)
//                    
//                    TextField("Enter ISBN number", text: $isbn)
//                        .keyboardType(.numberPad)
//                        .padding(.vertical, 12)
//                        .focused($isISBNFocused)
//                }
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.1))
//                )
//                
//                Text("Enter the 13-digit ISBN to identify the book")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.leading, 4)
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 40)
//            
//            Spacer()
//            
//            // Continue Button
//            Button(action: {
//                onContinue()
//            }) {
//                HStack {
//                    Text("Continue")
//                        .fontWeight(.semibold)
//                    
//                    Image(systemName: "arrow.right")
//                }
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 16)
//                .background(
//                    isbn.isEmpty ?
//                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.3)]), startPoint: .leading, endPoint: .trailing) :
//                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
//                )
//                .cornerRadius(16)
//                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
//            }
//            .disabled(isbn.isEmpty)
//            .padding(.horizontal, 20)
//            .padding(.bottom, 32)
//            .opacity(isbn.isEmpty ? 0.6 : 1.0)
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                isISBNFocused = true
//            }
//        }
//    }
//}
//
//struct BookDetailsStep: View {
//    let isbn: String
//    @Binding var bookTitle: String
//    @Binding var description: String
//    @Binding var totalCopies: Int
//    @Binding var availableCopies: Int
//    @Binding var reservedCopies: Int
//    @Binding var publishedDate: Date
//    @Binding var authorNames: [String]
//    @Binding var genreIds: [UUID]
//    @Binding var bookCover: UIImage?
//    @Binding var showImagePicker: Bool
//    let onSave: () -> Void
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        ScrollView(showsIndicators: false) {
//            VStack(spacing: 24) {
//                // Book Cover Section
//                VStack(spacing: 16) {
//                    if let cover = bookCover {
//                        Image(uiImage: cover)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 180, height: 260)
//                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
//                            )
//                    } else {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(Color.gray.opacity(0.1))
//                                .frame(width: 180, height: 260)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
//                                )
//                            
//                            VStack(spacing: 12) {
//                                Image(systemName: "book.closed")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(width: 60, height: 60)
//                                    .foregroundColor(.gray.opacity(0.5))
//                                
//                                Text("No Cover")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                    }
//                    
//                    Button(action: {
//                        showImagePicker = true
//                    }) {
//                        HStack {
//                            Image(systemName: bookCover == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath")
//                            Text(bookCover == nil ? "Add Cover" : "Change Cover")
//                        }
//                        .foregroundColor(.blue)
//                        .padding(.vertical, 10)
//                        .padding(.horizontal, 20)
//                        .background(Color.blue.opacity(0.1))
//                        .cornerRadius(20)
//                    }
//                }
//                .padding(.top, 20)
//                
//                // Form Fields
//                VStack(spacing: 16) {
//                    // Basic Info Section
//                    FormSection(title: "Basic Information") {
//                        FormTextField(title: "Title", placeholder: "Book title", text: $bookTitle)
//                        
//                        FormTextEditor(title: "Description", text: $description)
//                        
//                        FormDatePicker(title: "Published Date", date: $publishedDate)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("ISBN")
//                                .font(.subheadline)
//                                .foregroundColor(Color.text(for: colorScheme))
//                            
//                            HStack {
//                                Text(isbn)
//                                    .font(.body)
//                                    .padding()
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .background(Color.gray.opacity(0.05))
//                                    .cornerRadius(10)
//                                
//                                Image(systemName: "barcode")
//                                    .foregroundColor(.gray)
//                                    .font(.system(size: 18))
//                            }
//                        }
//                    }
//                    
//                    // Copy Management Section
//                    FormSection(title: "Copy Management") {
//                        FormStepper(title: "Total Copies", value: $totalCopies, range: 1...100)
//                        
//                        FormStepper(title: "Available Copies", value: $availableCopies, range: 0...totalCopies)
//                        
//                        FormStepper(title: "Reserved Copies", value: $reservedCopies, range: 0...totalCopies)
//                    }
//                    
//                    // Authors Section
//                    FormSection(title: "Authors") {
//                        ForEach(0..<authorNames.count, id: \.self) { index in
//                            HStack(spacing: 10) {
//                                TextField("Author name", text: $authorNames[index])
//                                    .padding()
//                                    .background(Color.gray.opacity(0.05))
//                                    .cornerRadius(10)
//                                
//                                Button(action: {
//                                    if authorNames.count > 1 {
//                                        authorNames.remove(at: index)
//                                    }
//                                }) {
//                                    Image(systemName: "minus.circle.fill")
//                                        .foregroundColor(.red)
//                                        .opacity(authorNames.count > 1 ? 1 : 0.3)
//                                }
//                                .disabled(authorNames.count <= 1)
//                                
//                                if index == authorNames.count - 1 {
//                                    Button(action: {
//                                        authorNames.append("")
//                                    }) {
//                                        Image(systemName: "plus.circle.fill")
//                                            .foregroundColor(.green)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal)
//                
//                // Save Button
//                Button(action: onSave) {
//                    Text("Save Book")
//                        .fontWeight(.semibold)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 16)
//                        .background(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                        .cornerRadius(16)
//                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 24)
//                .disabled(bookTitle.isEmpty)
//                .opacity(bookTitle.isEmpty ? 0.6 : 1.0)
//            }
//            .padding(.bottom, 40)
//        }
//    }
//}
//
//// MARK: - Helper Views
//
//struct FormSection<Content: View>: View {
//    let title: String
//    let content: Content
//    @Environment(\.colorScheme) private var colorScheme
//    
//    init(title: String, @ViewBuilder content: () -> Content) {
//        self.title = title
//        self.content = content()
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text(title)
//                .font(.headline)
//                .foregroundColor(Color.text(for: colorScheme))
//                .padding(.leading, 4)
//            
//            VStack(spacing: 16) {
//                content
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.gray.opacity(0.05))
//                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
//            )
//        }
//    }
//}
//
//struct FormTextField: View {
//    let title: String
//    let placeholder: String
//    @Binding var text: String
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(Color.text(for: colorScheme))
//            
//            TextField(placeholder, text: $text)
//                .padding()
//                .background(Color.gray.opacity(0.05))
//                .cornerRadius(10)
//        }
//    }
//}
//
//struct FormTextEditor: View {
//    let title: String
//    @Binding var text: String
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(Color.text(for: colorScheme))
//            
//            ZStack(alignment: .topLeading) {
//                if text.isEmpty {
//                    Text("Enter description...")
//                        .foregroundColor(.gray.opacity(0.7))
//                        .padding(.horizontal, 4)
//                        .padding(.vertical, 8)
//                }
//                
//                TextEditor(text: $text)
//                    .frame(minHeight: 100)
//                    .opacity(text.isEmpty ? 0.85 : 1)
//            }
//            .padding(8)
//            .background(Color.gray.opacity(0.05))
//            .cornerRadius(10)
//        }
//    }
//}
//
//struct FormDatePicker: View {
//    let title: String
//    @Binding var date: Date
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(Color.text(for: colorScheme))
//            
//            DatePicker("", selection: $date, displayedComponents: .date)
//                .datePickerStyle(CompactDatePickerStyle())
//                .labelsHidden()
//                .padding()
//                .background(Color.gray.opacity(0.05))
//                .cornerRadius(10)
//        }
//    }
//}
//
//struct FormStepper: View {
//    let title: String
//    @Binding var value: Int
//    let range: ClosedRange<Int>
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(Color.text(for: colorScheme))
//            
//            Spacer()
//            
//            HStack(spacing: 16) {
//                Button(action: {
//                    if value > range.lowerBound {
//                        value -= 1
//                    }
//                }) {
//                    Image(systemName: "minus.circle.fill")
//                        .font(.system(size: 24))
//                        .foregroundColor(value > range.lowerBound ? .blue : .gray)
//                }
//                
//                Text("\(value)")
//                    .font(.headline)
//                    .frame(minWidth: 30)
//                
//                Button(action: {
//                    if value < range.upperBound {
//                        value += 1
//                    }
//                }) {
//                    Image(systemName: "plus.circle.fill")
//                        .font(.system(size: 24))
//                        .foregroundColor(value < range.upperBound ? .blue : .gray)
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    BookAddViewAdmin()
//}

import SwiftUI

struct BookAddViewAdmin: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: BookAddStep = .isbn
    @State private var showImagePicker = false
    @State private var showBarcodeScanner = false
    @State private var bookData = BookData()
    var onSave: (BookModel) -> Void
    
    enum BookAddStep {
        case isbn
        case details
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
                BarcodeScannerView(scannedCode: $bookData.isbn)
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
            libraryId: UUID(), // You'll need to get the actual library ID
            title: bookData.bookTitle,
           coverImageUrl: coverImageUrl,
            coverImageData: coverImageData,
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
        )
        
        // Call the onSave closure with the new book
        onSave(newBook)
    }
}

#Preview {
    BookAddViewAdmin(onSave: { _ in })
}
