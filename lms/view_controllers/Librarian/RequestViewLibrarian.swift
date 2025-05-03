//
//  ManageViewLibrarian.swift
//  lms
//
//  Created by admin16 on 01/05/25.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

enum RequestType: String {
    case checkOut = "Check Out"
    case checkIn = "Check In"
}

struct BookRequest: Identifiable, Equatable {
    let id: UUID
    let type: RequestType
    let book: BookModel
    let user: User
    let requestDate: Date
    let dueDate: Date?
    
    static func == (lhs: BookRequest, rhs: BookRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Main View

struct RequestViewLibrarian: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSegment: RequestType = .checkOut
    @State private var showCamera = false
    @State private var selectedRequest: BookRequest?
    @State private var scannedBarcode: String = ""
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var cameraPermissionGranted = false
    @State private var requestToDelete: BookRequest?
    @State private var showDeleteConfirmation = false
    
    // Dummy data
    @State private var allRequests: [BookRequest] = [
        // Sample check-out request
        BookRequest(
            id: UUID(),
            type: .checkOut,
            book: BookModel(
                id: UUID(),
                libraryId: UUID(),
                title: "The Great Gatsby",
                isbn: "9781907308000",
                description: "Classic novel",
                totalCopies: 5,
                availableCopies: 3,
                reservedCopies: 2,
                authorIds: [UUID()],
                authorNames: ["F. Scott Fitzgerald"],
                genreIds: [UUID()],
                genreNames: ["Classics"],
                publishedDate: Date(),
                addedOn: Date(),
                updatedAt: Date(),
                coverImageUrl: nil,
                coverImageData: nil
            ),
            user: User(
                id: UUID(),
                email: "john@example.com",
                role: .member,
                name: "John Doe",
                is_active: true,
                library_id: "LIB123",
                borrowed_book_ids: [],
                reserved_book_ids: [],
                wishlist_book_ids: [],
                created_at: "2023-01-01",
                updated_at: "2023-01-01",
                profileImage: nil
            ),
            requestDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
        ),
        
        // Sample check-in request
        BookRequest(
            id: UUID(),
            type: .checkIn,
            book: BookModel(
                id: UUID(),
                libraryId: UUID(),
                title: "To Kill a Mockingbird",
                isbn: "9780061120084",
                description: "American classic",
                totalCopies: 7,
                availableCopies: 4,
                reservedCopies: 3,
                authorIds: [UUID()],
                authorNames: ["Harper Lee"],
                genreIds: [UUID()],
                genreNames: ["Classics"],
                publishedDate: Date(),
                addedOn: Date(),
                updatedAt: Date(),
                coverImageUrl: nil,
                coverImageData: nil
            ),
            user: User(
                id: UUID(),
                email: "jane@example.com",
                role: .member,
                name: "Jane Smith",
                is_active: true,
                library_id: "LIB123",
                borrowed_book_ids: [],
                reserved_book_ids: [],
                wishlist_book_ids: [],
                created_at: "2023-01-01",
                updated_at: "2023-01-01",
                profileImage: nil
            ),
            requestDate: Date(timeIntervalSinceNow: -86400 * 7),
            dueDate: Date(timeIntervalSinceNow: -86400) // Overdue by 1 day
        )
    ]
    
    var filteredRequests: [BookRequest] {
        let segmentFiltered = allRequests.filter { $0.type == selectedSegment }
        
        if searchText.isEmpty {
            return segmentFiltered
        }
        
        let lowercasedSearch = searchText.lowercased()
        return segmentFiltered.filter {
            $0.user.name.lowercased().contains(lowercasedSearch) ||
            $0.book.title.lowercased().contains(lowercasedSearch) ||
            ($0.book.isbn?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search users or books...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Segmented Control
                    Picker("Request Type", selection: $selectedSegment) {
                        ForEach([RequestType.checkOut, RequestType.checkIn], id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Request List
                    List {
                        ForEach(filteredRequests) { request in
                            RequestCardView(request: request) {
                                selectedRequest = request
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    requestToDelete = request
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Reject", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Book Requests")
            .sheet(isPresented: $showCamera) {
                if let request = selectedRequest {
                    BarcodeScannerView(scannedCode: $scannedBarcode) { barcode in
                        handleScannedBarcode(barcode, for: request)
                    }
                }
            }
            .alert("Scan Result", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Confirm Rejection", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reject", role: .destructive) {
                    if let request = requestToDelete {
                        withAnimation {
                            allRequests.removeAll { $0.id == request.id }
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to reject this request? This action cannot be undone.")
            }
            .onChange(of: selectedRequest) { newValue in
                if newValue != nil {
                    checkCameraPermission()
                }
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String, for request: BookRequest) {
        if barcode == request.book.isbn {
            withAnimation {
                // Remove the original request
                allRequests.removeAll { $0.id == request.id }
                
                // If it was a check-out, create a check-in request
                if request.type == .checkOut {
                    let newRequest = BookRequest(
                        id: UUID(),
                        type: .checkIn,
                        book: request.book,
                        user: request.user,
                        requestDate: Date(),
                        dueDate: request.dueDate
                    )
                    allRequests.append(newRequest)
                }
            }
            alertMessage = "Book successfully \(request.type == .checkOut ? "checked out" : "checked in")"
            showAlert = true
            showCamera = false
            selectedRequest = nil
        } else {
            alertMessage = "Wrong book scanned. Expected ISBN: \(request.book.isbn ?? "")"
            showAlert = true
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            DispatchQueue.main.async {
                showCamera = true
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraPermissionGranted = true
                        showCamera = true
                    } else {
                        alertMessage = "Camera access required for scanning"
                        showAlert = true
                        selectedRequest = nil
                    }
                }
            }
            
        default:
            DispatchQueue.main.async {
                alertMessage = "Please enable camera access in Settings"
                showAlert = true
                selectedRequest = nil
            }
        }
    }
}

// MARK: - Request Card View (unchanged)

struct RequestCardView: View {
    let request: BookRequest
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Info
            HStack(alignment: .top) {
                if let coverData = request.book.coverImageData,
                   let uiImage = UIImage(data: coverData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 90)
                        .cornerRadius(4)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let authors = request.book.authorNames {
                        Text("by \(authors.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let isbn = request.book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            
            // User Info
            HStack {
                if let userImageData = request.user.profileImage,
                   let uiImage = UIImage(data: userImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading) {
                    Text(request.user.name)
                        .font(.subheadline)
                    Text("ID: \(request.user.id.uuidString.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Fine Indicator
                VStack(alignment: .trailing) {
                    Text("Fine").font(.caption2)
                    Text("₹\(request.dueDate ?? Date() < Date() ? "50.00" : "0.00")")
                        .foregroundColor(request.dueDate ?? Date() < Date() ? .red : .green)
                }
            }
            
            // Dates
            if let dueDate = request.dueDate {
                HStack {
                    Text("Due Date:").font(.caption)
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(dueDate < Date() ? .red : .primary)
                }
            }
            
            // Action Button
            Button(action: action) {
                Text(request.type == .checkOut ? "Process Check Out" : "Process Check In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(request.dueDate ?? Date() < Date() ? .orange : .blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct RequestViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        RequestViewLibrarian()
    }
}
