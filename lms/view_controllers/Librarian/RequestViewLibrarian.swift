//
//  RequestViewLibrarian.swift
//  lms
//
//  Created by admin16 on 01/05/25.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Main View

enum BorrowRequestType: String, CaseIterable {
    case checkOut = "Check Out"
    case checkIn = "Check In"
}

struct RequestViewLibrarian: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSegment: BorrowRequestType = .checkOut
    @State private var showCamera = false
    @State private var selectedBorrow: BorrowModel?
    @State private var selectedReservation: ReservationModel?
    @State private var scannedBarcode: String = ""
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var cameraPermissionGranted = false
    @State private var borrowToDelete: BorrowModel?
    @State private var reservationToDelete: ReservationModel?
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var borrowRequests: [BorrowModel] = []
    @State private var reservation:[ReservationModel] = []
    @State private var fetchError: String?
    @State private var showCheckInOutModal = false
    @State private var checkInOutMode: CheckInOutModalView.Mode = .checkOut
    @State private var isProcessingCheckout = false
    @State private var checkoutResultMessage: String? = nil
    private var itemCount: Int {
        return selectedSegment == .checkOut ? filteredReservations.count : filteredBorrowRequests.count
    }
    
    var filteredReservations: [ReservationModel] {
        reservation
    }

    var filteredBorrowRequests: [BorrowModel] {
        let filtered: [BorrowModel] = borrowRequests.filter{$0.status != .returned}
        if searchText.isEmpty {
            return filtered
        }
        
        let lowercasedSearch = searchText.lowercased()
        return filtered.filter {
            ($0.book?.title.lowercased().contains(lowercasedSearch) ?? false) ||
            ($0.book?.isbn?.lowercased().contains(lowercasedSearch) ?? false) ||
            ($0.book?.description?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                VStack(spacing: 16) {
                    // Search Bar
                    searchBar
                    
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    // Request Count
                    requestCountView
                    .padding(.horizontal)
                    
                    // Request List
                    requestList
                }
                .padding(.top)
                // --- Check In/Out Modal ---
                .sheet(isPresented: $showCheckInOutModal, onDismiss: { selectedBorrow = nil }) {
                    if true {
                        CheckInOutModalView(
                            borrow: selectedBorrow,
                            reservation: selectedReservation,
                            mode: checkInOutMode,
                            onComplete: { success in
                                if success {
                                    borrowRequests.removeAll { $0.id == selectedBorrow?.id ?? nil }
                                }
                                showCheckInOutModal = false
                                selectedBorrow = nil
                            }
                        )
                    }
                }
            }
            .navigationTitle("Book Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchBorrowRequests) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                if let borrow = selectedBorrow {
                    BarcodeScannerView(scannedCode: $scannedBarcode) { barcode in
                        handleScannedBarcode(barcode, for: borrow)
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
                    if let borrow = borrowToDelete {
                        Task {
                            do {
                                try await BorrowHandler.shared.cancelBorrow(borrow.id)
                                await MainActor.run {
                                    borrowRequests.removeAll { $0.id == borrow.id }
                                }
                            } catch {
                                await MainActor.run {
                                    alertMessage = "Failed to reject request: \(error.localizedDescription)"
                                    showAlert = true
                                }
                            }
                        }
                    }
                    if let reservation = reservationToDelete {
                        Task{
                            do{
                                try await ReservationHandler.shared.cancelReservation(reservation.id)
                                await MainActor.run {
                                    self.reservation.removeAll{ $0.id == reservation.id}
                                }
                            }catch{
                                alertMessage = "Failed to reject request: \(error.localizedDescription)"
                                showAlert = true
                            }
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to reject this request? This action cannot be undone.")
            }
            .onChange(of: selectedBorrow) { newValue in
                if newValue != nil {
                    checkCameraPermission()
                }
            }
            .onAppear {
                fetchBorrowRequests()
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search by title, ISBN or description...", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var segmentedControl: some View {
        Picker("Request Type", selection: $selectedSegment) {
            ForEach(BorrowRequestType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var requestCountView: some View {
        HStack {
            Text("\(itemCount) \(itemCount == 1 ? "request" : "requests") found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var requestList: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading requests...")
                    Spacer()
                }
            } else if let error = fetchError {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            fetchBorrowRequests()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                    Spacer()
                }
            } else if (filteredReservations.isEmpty && selectedSegment == .checkOut) || (filteredBorrowRequests.isEmpty && selectedSegment == .checkIn) {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: selectedSegment == .checkOut ? "tray" : "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No \(selectedSegment.rawValue) Requests")
                            .font(.headline)
                        Text("There are no \(selectedSegment == .checkOut ? "check out" : "check in") requests at this time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if(selectedSegment == .checkOut){
                            ForEach(filteredReservations) { borrow in
                                BorrowRequestCardView(
                                    borrow: nil,
                                    reservation: borrow,
                                    type: selectedSegment,
                                    onProcess: {
                                        selectedReservation = borrow
                                        checkInOutMode = (selectedSegment == .checkOut ? .checkOut : .checkIn)
                                        showCheckInOutModal = true
                                    },
                                    onReject: {
                                        reservationToDelete = borrow
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }else{
                            ForEach(filteredBorrowRequests) { borrow in
                                BorrowRequestCardView(
                                    borrow: borrow,
                                    reservation: nil,
                                    type: selectedSegment,
                                    onProcess: {
                                        selectedBorrow = borrow
                                        checkInOutMode = (selectedSegment == .checkOut ? .checkOut : .checkIn)
                                        showCheckInOutModal = true
                                    },
                                    onReject: {
                                        borrowToDelete = borrow
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }

                        }
                    }
                    .padding(.vertical)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - Helper Methods
    
    private func handleScannedBarcode(_ barcode: String, for borrow: BorrowModel) {
        guard let book = borrow.book else {
            alertMessage = "Book data missing."
            showAlert = true
            return
        }
        
        let bookIsbn = book.isbn ?? ""
        
        if barcode == bookIsbn {
            // Here you would call the API to process the check out/in
            // For now, just remove from the list and show success
            withAnimation {
                borrowRequests.removeAll { $0.id == borrow.id }
            }
            alertMessage = selectedSegment == .checkOut ? "Book successfully checked out" : "Book successfully checked in"
            showAlert = true
            showCamera = false
            selectedBorrow = nil
        } else {
            alertMessage = "Wrong book scanned. Expected ISBN: \(bookIsbn)"
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
                        selectedBorrow = nil
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                alertMessage = "Please enable camera access in Settings"
                showAlert = true
                selectedBorrow = nil
            }
        }
    }

    private func fetchBorrowRequests() {
        isLoading = true
        fetchError = nil
        
        Task {
            do {
                let borrows = try await BorrowHandler.shared.getBorrows()
                reservation = try await ReservationHandler.shared.getReservations()
                // Debug print to verify book object
                if let first = borrows.first {
                    print("DEBUG: First borrow: \(first)")
                    print("DEBUG: First borrow.book: \(String(describing: first.book))")
                }
                await MainActor.run {
                    self.borrowRequests = borrows
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.fetchError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Borrow Request Card View

struct BorrowRequestCardView: View {
    let borrow: BorrowModel?
    let reservation: ReservationModel?
    let type: BorrowRequestType
    let onProcess: () -> Void
    let onReject: () -> Void
    var book:BookModel{
        if(type == .checkOut){
            return reservation!.book!
        }
        return borrow!.book!
    }
    var borrowId:UUID{
        if(type == .checkOut){
            return reservation!.id
        }
        return borrow!.id
    }
    var reservationTime:Date{
        if(type == .checkOut){
            return reservation!.reserved_at
        }
        return borrow!.borrow_date
    }
    var dueTime:Date?{
        if(type == .checkOut){
            return reservation!.expires_at
        }
        return borrow?.return_date
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book Info Section (No User Info Bar to avoid UserModel issues)
            bookInfoSection
            
            // Status Bar
            statusBar
            
            // Action Buttons
            buttonSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Component Views
    
    // Removed userInfoBar to avoid UserModel decoding issues
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User & Status Header
            HStack {
                // We're not using user.name directly to avoid UserModel decoding issues
                Text("Request ID: \(borrowId.uuidString.prefix(8))...")
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                statusBadge
            }
            .padding()
            
            Divider()
            
            HStack(alignment: .top, spacing: 16) {
                // Book Cover
                bookCover
                
                // Book Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title ?? "Unknown Title")
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let isbn = book.isbn {
                        HStack {
                            Image(systemName: "barcode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(isbn)
                                .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                        HStack {
                            Image(systemName: "books.vertical")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Text("\(book.availableCopies) of \(book.totalCopies) available")
                                .font(.caption)
                                .foregroundColor(book.availableCopies > 0 ? .green : .red)
                        }
                    
                    
                    // Request Dates
                    dateView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private var statusBar: some View {
        HStack {
            Text("Request Status:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
                Spacer()
            
            Text(statusText)
                .font(.subheadline.bold())
                .foregroundColor(.orange)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
    }
    
    private var buttonSection: some View {
        HStack(spacing: 12) {
            Button(action: onProcess) {
                HStack {
                    Image(systemName: type == .checkOut ? "arrow.right.doc.on.clipboard" : "arrow.left.doc.on.clipboard")
                    Text(type == .checkOut ? "Check Out" : "Check In")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button(action: onReject) {
            HStack {
                    Image(systemName: "xmark")
                    Text("Reject")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
    }
    
    // MARK: - Supporting Views
    
    private var bookCover: some View {
        Group {
            if let coverUrl = book.coverImageUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 120)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }
    
    private var dateView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                
                Text("Requested: \(reservationTime.formatted(date: .numeric, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let dueTime = dueTime{
                        Text("Due: \(dueTime.formatted(date: .numeric, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(dueTime < Date() ? .red : .secondary)
                    }
                }
            
        }
    }
    
    private var statusBadge: some View {
        Text("Reserved")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        .orange
    }
    
    private var statusText: String {
            return "Waiting for Approval"
        
    }
    
    // Add a simple helper to get book ISBN safely
    private var bookIsbn: String {
        return book.isbn ?? "No ISBN"
    }
}

// MARK: - Previews

struct RequestViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        RequestViewLibrarian()
    }
}
