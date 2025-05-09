//
//  NotificationManager.swift
//  lms
//
//  Created by Diptayan Jash on 09/05/25.
//

import Foundation
import SwiftUI  // Added to ensure general Swift types and Calendar are available
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // Request notification permissions from the user
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }

    // Schedule a notification for an upcoming due date
    func scheduleDueDateNotification(for borrow: BorrowModel, daysInAdvance: Int = 3) {
        Task {
            guard let dueDate = await calculateDueDateAsync(for: borrow) else {
                print(
                    "Failed to calculate due date for book: \(borrow.book?.title ?? "Unknown book (\(borrow.book_id.uuidString))") for 'due soon' notification."
                )
                return
            }

            let notificationDate = Calendar.current.date(
                byAdding: .day, value: -daysInAdvance, to: dueDate)
            guard let notificationDate = notificationDate else { return }

            // Don't schedule if notification date is in the past
            if notificationDate <= Date() {
                print(
                    "Notification date for \(borrow.book?.title ?? "Unknown book") is in the past. No 'due soon' notification scheduled."
                )
                return
            }

            let bookTitle = borrow.book?.title ?? "Your borrowed book"
            let content = UNMutableNotificationContent()
            content.title = "Book Due Soon"
            content.body =
                "\(bookTitle) is due in \(daysInAdvance) days (on \(dueDate.mediumFormatted)). Please return it to avoid fines."
            content.sound = UNNotificationSound.default

            let identifier = "due_date_\(borrow.id.uuidString)"
            // Ensure notification time is reasonable, e.g., 9 AM
            var dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day], from: notificationDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            guard let triggerDateWithTime = Calendar.current.date(from: dateComponents) else {
                print(
                    "Failed to create trigger date with time. Scheduling with original notificationDate."
                )
                let fallbackComponents = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: notificationDate)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: fallbackComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print(
                            "Error scheduling due date notification (fallback): \(error.localizedDescription)"
                        )
                    } else {
                        print(
                            "Successfully scheduled (fallback) 'due soon' notification for \(bookTitle) on \(notificationDate.mediumFormatted) at \(notificationDate.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                }
                return
            }

            // Re-check if notification date is in the past after setting time
            if triggerDateWithTime <= Date() {
                print(
                    "Notification trigger time for \(borrow.book?.title ?? "Unknown book") is in the past after setting to 9 AM. No 'due soon' notification scheduled."
                )
                return
            }

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling due date notification: \(error.localizedDescription)")
                } else {
                    print(
                        "Successfully scheduled 'due soon' notification for \(bookTitle) on \(triggerDateWithTime.mediumFormatted) at \(triggerDateWithTime.formatted(date: .omitted, time: .shortened))"
                    )
                }
            }
        }
    }

    // Also schedule a notification for the due date itself
    func scheduleDueDateExactNotification(for borrow: BorrowModel) {
        Task {
            guard let dueDate = await calculateDueDateAsync(for: borrow) else {
                print(
                    "Failed to calculate due date for book: \(borrow.book?.title ?? "Unknown book (\(borrow.book_id.uuidString))") for 'due today' notification."
                )
                return
            }

            var dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day], from: dueDate)
            dateComponents.hour = 9  // 9 AM on the due date
            dateComponents.minute = 0

            guard let notificationTriggerDate = Calendar.current.date(from: dateComponents) else {
                return
            }

            // Don't schedule if notification date is in the past or already passed for today
            if notificationTriggerDate <= Date() {
                print(
                    "Due date \(dueDate.mediumFormatted) for \(borrow.book?.title ?? "Unknown book") is in the past or already passed for notification trigger. No 'due today' notification scheduled."
                )
                return
            }

            let bookTitle = borrow.book?.title ?? "Your borrowed book"
            let content = UNMutableNotificationContent()
            content.title = "Book Due Today"
            content.body =
                "\(bookTitle) is due today. Please return it to the library to avoid fines."
            content.sound = UNNotificationSound.default

            let identifier = "due_today_\(borrow.id.uuidString)"
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents, repeats: false)  // Use dateComponents for the trigger
            let request = UNNotificationRequest(
                identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling due today notification: \(error.localizedDescription)")
                } else {
                    print(
                        "Successfully scheduled 'due today' notification for \(bookTitle) on \(notificationTriggerDate.mediumFormatted) at \(notificationTriggerDate.formatted(date: .omitted, time: .shortened))"
                    )
                }
            }
        }
    }

    // Schedule notifications for all currently borrowed books
    func scheduleNotificationsForAllBorrowedBooks(borrows: [BorrowModel]) {
        print("Attempting to schedule notifications for \(borrows.count) borrows.")
        for borrow in borrows {
            if borrow.status == .borrowed {
                if borrow.book != nil {
                    scheduleDueDateNotification(for: borrow, daysInAdvance: 3)  // e.g., 3 days before
                    scheduleDueDateExactNotification(for: borrow)  // On the due date
                } else {
                    print(
                        "Skipping notification for borrow ID \(borrow.id) because book details are missing."
                    )
                }
            }
        }
    }

    // Remove all scheduled notifications for a specific book
    func removeDueDateNotifications(for borrowId: UUID) {
        let identifiers = [
            "due_date_\(borrowId.uuidString)",
            "due_today_\(borrowId.uuidString)",
        ]
        print("Removing notifications for borrow ID: \(borrowId.uuidString)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers)
    }

    // Remove all scheduled notifications
    func removeAllDueDateNotifications() {
        print("Removing all pending due date notifications.")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // Async version of calculateDueDate for more accurate calculations
    // This version wraps the existing fetchPolicy completion handler.
    private func calculateDueDateAsync(for borrow: BorrowModel) async -> Date? {
        // First check if return_date is already set (book already returned)
        if let returnDate = borrow.return_date {
            // If a book is returned, its due date is effectively its return date,
            // but notifications are for upcoming dues. So, for returned books,
            // we shouldn't schedule. This check is also in scheduleNotificationsForAllBorrowedBooks (status check).
            // However, if this function is called for other purposes, this is relevant.
            // For notification scheduling, this borrow shouldn't reach here if status is 'returned'.
            print(
                "Book \(borrow.book?.title ?? "ID: \(borrow.book_id.uuidString)") already returned on \(returnDate.mediumFormatted). No due date calculation needed for notification."
            )
            return nil  // Or return returnDate if the context implies "final date"
        }

        // Ensure borrow.book is not nil for policy lookup
        guard let book = borrow.book else {
            print(
                "Error: Book data is nil for borrow ID: \(borrow.id). Book ID: \(borrow.book_id.uuidString). Falling back to default 14-day borrow period."
            )
            return Calendar.current.date(byAdding: .day, value: 14, to: borrow.borrow_date)
        }
        let libraryIdForBook = book.libraryId

        // Wrap the completion handler-based fetchPolicy in an async function
        // Note: The provided global fetchPolicy function ignores its libraryId parameter and uses KeychainManager.shared.getLibraryId()
        // So, libraryIdForBook passed here will effectively be ignored by the current fetchPolicy implementation.
        // The policy fetched will be for the library ID stored in Keychain.
        print(
            "Calculating due date for book '\(book.title)': Fetching policy (book's libraryId: \(libraryIdForBook.uuidString), borrow date: \(borrow.borrow_date.mediumFormatted))."
        )

        let fetchedPolicy: Policy? = await withCheckedContinuation { continuation in
            fetchPolicy(libraryId: libraryIdForBook) { policyFromCompletion in  // libraryIdForBook is passed but might be ignored by fetchPolicy
                continuation.resume(returning: policyFromCompletion)
            }
        }

        if let policy = fetchedPolicy {
            // Ensure max_borrow_days is a positive value to avoid issues with date calculation
            guard policy.max_borrow_days > 0 else {
                print(
                    "Policy found for library but max_borrow_days is invalid (\(policy.max_borrow_days)). Falling back to default 14-day borrow period for book: \(book.title)."
                )
                return Calendar.current.date(byAdding: .day, value: 14, to: borrow.borrow_date)
            }
            print(
                "Policy found (max_borrow_days: \(policy.max_borrow_days)). Calculating due date for book: \(book.title)."
            )
            return Calendar.current.date(
                byAdding: .day, value: policy.max_borrow_days, to: borrow.borrow_date)
        } else {
            print(
                "No policy found or error fetching policy. Falling back to default 14-day borrow period for book: \(book.title)."
            )
            return Calendar.current.date(byAdding: .day, value: 14, to: borrow.borrow_date)
        }
    }

    // Synchronous calculateDueDate (existing, for immediate UI if needed, less accurate for notifications)
    // This is kept as per original file, but notifications should use the async version.
    private func calculateDueDate(for borrow: BorrowModel) -> Date? {
        if let returnDate = borrow.return_date {
            return returnDate
        }
        // This is a fallback, async version is preferred for notifications.
        // For UI that needs immediate, possibly less accurate data, this might be used.
        // However, for consistency, UI should also strive to use policy-based calculation.
        // The BookCardView seems to do this with its own policy state.
        print(
            "(Sync calculation) Defaulting to 14 days for book: \(borrow.book?.title ?? "Unknown")")
        return Calendar.current.date(byAdding: .day, value: 14, to: borrow.borrow_date)
    }
}

// Extension to Date for better formatting (existing)
extension Date {
    var mediumFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var daysFromToday: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: self)
        ).day ?? 0
    }

    var isOverdue: Bool {
        return self < Calendar.current.startOfDay(for: Date())  // Compare with start of today
    }
}
