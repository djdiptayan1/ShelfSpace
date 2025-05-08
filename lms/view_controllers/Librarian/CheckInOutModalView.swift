import SwiftUI
import Foundation

struct CheckInOutModalView: View {
    enum Mode {
        case checkOut, checkIn
    }
    let borrow: BorrowModel?
    let reservation: ReservationModel?
    let mode: Mode
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isbnInput: String = ""
    @State private var showScanner = false
    @State private var isProcessing = false
    @State private var resultMessage: String? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var confirmWithoutISBN = false

    private var bookHasISBN: Bool {
        if(mode == .checkOut){
            return reservation?.book?.isbn != nil && !(reservation?.book?.isbn?.isEmpty ?? true)
        }
        return borrow?.book?.isbn != nil && !(borrow?.book?.isbn?.isEmpty ?? true)
    }

    private var bookTitle: String {
        if(mode == .checkOut){
            return reservation?.book?.title ?? "Book ID: \(reservation?.book_id)"
        }
        return borrow?.book?.title ?? "Book ID: \(borrow?.book_id)"
    }

    var body: some View {
        VStack(spacing: 24) {
            if let result = resultMessage {
                VStack(spacing: 16) {
                    Image(systemName: result.contains("success") ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .font(.system(size: 48))
                        .foregroundColor(result.contains("success") ? .green : .red)
                        .accessibilityHidden(true)

                    Text(result)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(result)

                    Button("Close") {
                        dismiss()
                        onComplete(result.contains("success"))
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Close and return")
                    .accessibilityHint("Closes this window and completes the process")
                }
            } else if confirmWithoutISBN {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text("This book doesn't have an ISBN")
                        .font(.headline)
                        .accessibilityLabel("This book doesn't have an ISBN")

                    Text("Do you want to \(mode == .checkOut ? "check out" : "check in") \"\(bookTitle)\" without ISBN verification?")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Proceed without ISBN verification")
                        .accessibilityHint("Confirms the action without checking ISBN")

                    HStack {
                        Button("Cancel") {
                            confirmWithoutISBN = false
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Cancels and returns to previous screen")

                        Button("Proceed") {
                            processDirectly()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Proceed")
                        .accessibilityHint("Confirms and continues the process without ISBN")
                    }
                    .padding(.top)
                }
            } else {
                Text(mode == .checkOut ? "Check Out Book" : "Check In Book")
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                if bookHasISBN {
                    Text("Enter or scan the ISBN to verify \"\(bookTitle)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Enter or scan the ISBN to verify the book titled \(bookTitle)")

                    HStack {
                        TextField("Enter ISBN", text: $isbnInput)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: isbnInput) { newValue in
                                isbnInput = newValue.filter { $0.isNumber }
                                if isbnInput.count > 13 { isbnInput = String(isbnInput.prefix(13)) }
                            }
                            .accessibilityLabel("ISBN input field")
                            .accessibilityHint("Enter the ISBN number")

                        Button(action: { showScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                                .padding(8)
                        }
                        .accessibilityLabel("Scan ISBN")
                        .accessibilityHint("Opens camera to scan ISBN barcode")
                    }
                    .padding(.horizontal)

                    Button(action: { process(isbn: isbnInput) }) {
                        if isProcessing {
                            ProgressView()
                                .accessibilityLabel("Processing")
                        } else {
                            Text(mode == .checkOut ? "Check Out" : "Check In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isbnInput.isEmpty || isProcessing)
                    .padding()
                    .background((isbnInput.isEmpty || isProcessing) ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .accessibilityLabel(mode == .checkOut ? "Check out book" : "Check in book")
                    .accessibilityHint("Submits the ISBN and performs the operation")
                } else {
                    VStack(spacing: 16) {
                        Text("Book: \"\(bookTitle)\"")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityLabel("Book title: \(bookTitle)")

                        Text("This book doesn't have an ISBN recorded in the system.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .accessibilityLabel("This book doesn't have an ISBN recorded in the system")

                        Button(action: { confirmWithoutISBN = true }) {
                            if isProcessing {
                                ProgressView()
                                    .accessibilityLabel("Processing")
                            } else {
                                Text(mode == .checkOut ? "Process Check Out" : "Process Check In")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(isProcessing)
                        .padding()
                        .background(isProcessing ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .accessibilityLabel(mode == .checkOut ? "Process check out without ISBN" : "Process check in without ISBN")
                        .accessibilityHint("Checks the book in or out without ISBN verification")
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView(scannedCode: $isbnInput) { code in
                await processAsync(isbn: code)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { showError = false }
        } message: {
            Text(errorMessage)
                .accessibilityLabel("Error: \(errorMessage)")
        }
    }

    private func process(isbn: String) {
        guard let book = mode == .checkOut ? reservation?.book : borrow?.book else {
            errorMessage = "Book data missing."; showError = true; return
        }

        if let expectedIsbn = book.isbn, !expectedIsbn.isEmpty {
            if isbn != expectedIsbn {
                errorMessage = "ISBN does not match. Expected: \(expectedIsbn)"; showError = true; return
            }
        }

        isProcessing = true
        Task {
            do {
                if mode == .checkOut {
                    if let borrow = reservation {
                        _ = try await BorrowHandler.shared.borrow(bookId: borrow.book_id, userId: borrow.user_id)
                        await MainActor.run {
                            resultMessage = "Book successfully checked out!"
                            isProcessing = false
                        }
                    }
                } else {
                    if let borrow = borrow {
                        _ = try await BorrowHandler.shared.returnBorrow(borrow.id)
                        await MainActor.run {
                            resultMessage = "Book successfully checked in!"
                            isProcessing = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    resultMessage = "Operation failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }

    private func processDirectly() {
        isProcessing = true
        Task {
            do {
                if mode == .checkOut {
                    if let borrow = reservation {
                        _ = try await BorrowHandler.shared.borrow(bookId: borrow.book_id, userId: borrow.user_id)
                        await MainActor.run {
                            resultMessage = "Book successfully checked out!"
                            isProcessing = false
                        }
                    }
                } else {
                    if let borrow = borrow {
                        _ = try await BorrowHandler.shared.returnBorrow(borrow.id)
                        await MainActor.run {
                            resultMessage = "Book successfully checked in!"
                            isProcessing = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    resultMessage = "Operation failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }

    private func processAsync(isbn: String) async {
        guard let book = mode == .checkOut ? reservation?.book : borrow?.book else {
            await MainActor.run {
                errorMessage = "Book data missing."
                showError = true
            }
            return
        }

        if let expectedIsbn = book.isbn, !expectedIsbn.isEmpty {
            if isbn != expectedIsbn {
                await MainActor.run {
                    errorMessage = "ISBN does not match. Expected: \(expectedIsbn)"
                    showError = true
                }
                return
            }
        }

        isProcessing = true
        do {
            if mode == .checkOut {
                if let borrow = reservation {
                    _ = try await BorrowHandler.shared.borrow(bookId: borrow.book_id, userId: borrow.user_id)
                    await MainActor.run {
                        resultMessage = "Book successfully checked out!"
                        isProcessing = false
                    }
                }
            } else {
                if let borrow = borrow {
                    _ = try await BorrowHandler.shared.returnBorrow(borrow.id)
                    await MainActor.run {
                        resultMessage = "Book successfully checked in!"
                        isProcessing = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                resultMessage = "Operation failed: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
}
