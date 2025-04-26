//
//  ReservationSettingsView.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
import SwiftUI
import DotLottie

struct ReservationSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var policyViewModel: PolicyViewModel

    // State variables for reservation settings
    @State private var holdDurationHours: Double = 7 * 24 // Default to 7 days in hours
    @State private var maxBooksReservable: Double = 5 // Default
    @State private var showingSaveAlert: Bool = false

    private func policyDaysToSliderHours(_ days: Int?) -> Double {
        guard let validDays = days, validDays >= 0 else { return 7 * 24 }
        return max(1, Double(validDays * 24))
    }

    private func sliderHoursToPolicyDays(_ hours: Double) -> Int {
        return max(0, Int(round(hours / 24.0)))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background layer
                ReusableBackground(colorScheme: colorScheme)

                // Content layer
                VStack {
                    // Header
                    HStack {
                        // iOS native style cancel button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.red)
                        }

                        Spacer()

                        Text("Reservation Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.text(for: colorScheme))

                        Spacer()

                        // Save button
                        Button(action: {
                            saveSettings()
                        }) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.primary(for: colorScheme))
                        }
                        .disabled(policyViewModel.isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    if policyViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding(.vertical, 30)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 30) {
                                // Maximum Books Reservable Card
//                                VStack(alignment: .leading, spacing: 15) {
//                                    Text("Maximum Books Reservable")
//                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
//                                        .foregroundColor(Color.text(for: colorScheme))
//
//                                    Text("\(Int(maxBooksReservable)) Books")
//                                        .font(.system(size: 36, weight: .bold, design: .rounded))
//                                        .foregroundColor(Color.primary(for: colorScheme))
//                                        .frame(maxWidth: .infinity, alignment: .center)
//                                        .padding(.vertical, 10)
//
//                                    // iOS-style slider
//                                    Slider(value: $maxBooksReservable, in: 1...10, step: 1)
//                                        .accentColor(Color.primary(for: colorScheme))
//                                        .padding(.vertical, 10)
//
//                                    HStack {
//                                        Text("1 Book")
//                                            .font(.system(size: 14))
//                                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//
//                                        Spacer()
//
//                                        Text("10 Books")
//                                            .font(.system(size: 14))
//                                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                    }
//                                }
//                                .padding(20)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 15)
//                                        .fill(colorScheme == .dark ?
//                                              Color(hex: ColorConstants.darkBackground).opacity(0.7) :
//                                              Color.white.opacity(0.9))
//                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                                )

                                // Hold Duration Card
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Hold Duration")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.text(for: colorScheme))

                                    Text("\(Int(holdDurationHours)) Hours")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.primary(for: colorScheme))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 10)

                                    // iOS-style slider
                                    Slider(value: $holdDurationHours, in: 1 ... 48, step: 1)
                                        .accentColor(Color.primary(for: colorScheme))
                                        .padding(.vertical, 10)

                                    HStack {
                                        Text("1 Hour")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                                        Spacer()

                                        Text("48 Hours")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(colorScheme == .dark ?
                                            Color(hex: ColorConstants.darkBackground).opacity(0.7) :
                                            Color.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true) // Hide the navigation bar completely
            .onAppear {
                // Load current policy values when the view appears
                if let policy = policyViewModel.currentPolicy {
                    // Update state variables from the loaded policy
                    self.holdDurationHours = policyDaysToSliderHours(policy.reservation_expiry_days)
                    self.maxBooksReservable = Double(policy.max_books_per_user) // Assuming max_books_per_user is Int
                } else {
                    // If no policy exists yet, maybe load defaults or trigger a fetch
                    // The ViewModel's loadPolicy should handle fetching
                    print("Policy not loaded yet or doesn't exist.")
                    // You might want to ensure loadPolicy is called if currentPolicy is nil
                    // policyViewModel.loadPolicy() // Or ensure it's called before presenting this view
                }
            }.alert(isPresented: $showingSaveAlert) {
                // Use the separate error message from ViewModel for better detail
                if let error = policyViewModel.errorMessage {
                    return Alert(
                        title: Text("Error"),
                        message: Text(error),
                        dismissButton: .default(Text("OK"))
                    )
                } else { // Assuming success if no error message
                    return Alert(
                        title: Text("Success"),
                        message: Text("Reservation settings saved successfully."),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .overlay(
                Group {
                    if policyViewModel.showAnimation {
                        DotLottieAnimation(
                            fileName: "policy",
                            config: AnimationConfig(
                                autoplay: true,
                                loop: true,
                                mode: .bounce,
                                speed: 1.5
                            )
                        )
                        .view()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                    }
                }
            )
        }
    }

    // Save the settings using PolicyViewModel
    private func saveSettings() {
        // Convert hours to days (rounding up to ensure at least 1 day)
        let expiryDays = max(1, Int(ceil(holdDurationHours / 24.0)))
        let maxBooks = Int(maxBooksReservable)

        // Check if we are updating an existing policy or creating a new one
        if var policyToSave = policyViewModel.currentPolicy {
            // Update the policy copy with the new values from the sliders
            policyToSave.reservation_expiry_days = expiryDays
            policyToSave.max_books_per_user = maxBooks

            // Now pass the *modified* policy to the view model
            policyViewModel.savePolicy(policy: policyToSave) { _ in
                self.showingSaveAlert = true
            }
        } else {
            // Create a new policy if one doesn't exist
            let newPolicy = Policy(
                library_id: policyViewModel.libraryId,
                max_borrow_days: 30,
                fine_per_day: Decimal(1.0),
                max_books_per_user: maxBooks,
                reservation_expiry_days: expiryDays
            )
            policyViewModel.savePolicy(policy: newPolicy) { _ in
                self.showingSaveAlert = true
            }
        }
    }
}
