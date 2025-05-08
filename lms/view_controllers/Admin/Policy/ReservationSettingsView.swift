//
//  ReservationSettingsView.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import DotLottie
import Foundation
import SwiftUI

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
                        .accessibilityLabel("Cancel button")
                        .accessibilityHint("Dismisses the settings view")

                        Spacer()

                        Text("Reservation Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.text(for: colorScheme))
                            .accessibilityAddTraits(.isHeader)

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
                        .accessibilityLabel("Save button")
                        .accessibilityHint("Saves the reservation settings")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    // if policyViewModel.isLoading {
                    //     ProgressView()
                    //         .progressViewStyle(CircularProgressViewStyle())
                    //         .scaleEffect(1.5)
                    //         .padding(.vertical, 30)
                    // } else {
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
                                    .accessibilityAddTraits(.isHeader)

                                Text("\(Int(holdDurationHours)) Hours")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                    .accessibilityValue("\(Int(holdDurationHours)) hours selected")

                                // iOS-style slider
                                Slider(value: $holdDurationHours, in: 1 ... 48, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                    .accessibilityLabel("Hold Duration Slider")
                                    .accessibilityValue("\(Int(holdDurationHours)) hours")
                                    .accessibilityHint("Adjusts the hold duration from 1 to 48 hours")

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
            // }
            .navigationBarHidden(true)
            .alert(isPresented: $showingSaveAlert) {
                if let error = policyViewModel.errorMessage {
                    return Alert(
                        title: Text("Error"),
                        message: Text(error),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
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
                        .accessibilityHidden(true)
                    }
                }
            )
            .onAppear {
                // Load current policy values when the view appears
                if let policy = policyViewModel.currentPolicy {
                    holdDurationHours = policyDaysToSliderHours(policy.reservation_expiry_days)
                    holdDurationHours = Double(truncating: policy.reservation_expiry_days as NSNumber)
                    self.maxBooksReservable = Double(policy.max_books_per_user)
                } else {
                    print("Policy not loaded yet or doesn't exist.")
                }
            }
        }
    }

    // Save the settings using PolicyViewModel
    private func saveSettings() {
        // Store expiry in hours directly
        let expiryHours = Int(holdDurationHours)
        let maxBooks = Int(maxBooksReservable)

        if let currentPolicy = policyViewModel.currentPolicy {
            var updatedPolicy = currentPolicy
            updatedPolicy.reservation_expiry_days = expiryHours
            updatedPolicy.max_books_per_user = maxBooks

            policyViewModel.savePolicy(policy: updatedPolicy) { success in
                if success {
                    showingSaveAlert = true
                }
            }
        } else {
            let newPolicy = Policy(
                library_id: policyViewModel.libraryId,
                max_borrow_days: 30,
                fine_per_day: Decimal(1.0),
                max_books_per_user: maxBooks,
                reservation_expiry_days: expiryHours
            )
            policyViewModel.savePolicy(policy: newPolicy) { success in
                if success {
                    showingSaveAlert = true
                }
            }
        }
    }
}
