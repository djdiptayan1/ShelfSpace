//
//  ManagePoliciesAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI

struct ManagePoliciesAdmin: View {
    // Policy items to display in the list
    private let policyItems = [
        "Fines and Overdue Items",
        "Reservation Policy",
        "Borrowing Policy",
        "Privacy Policy"
    ]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingFineSettings = false
    @State private var showingReservationSettings = false
    @State private var showingBorrowingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background layer
                ReusableBackground(colorScheme: colorScheme)
                
                // Content layer
                VStack(spacing: 16) { // Increased spacing between items
                    Text("Library Policies")
                        .font(.system(size: 28, weight: .bold, design: .rounded)) // Increased heading size
                        .foregroundColor(Color.text(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 25) // Increased top padding
                        .padding(.bottom, 10) // Added bottom padding
    
                    // Policy items list
                    ForEach(policyItems, id: \.self) { policy in
                        Group {
                            if policy == "Fines and Overdue Items" {
                                // Custom button for the Fines policy
                                Button(action: {
                                    showingFineSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else if policy == "Reservation Policy" {
                                // Custom button for the Reservation policy
                                Button(action: {
                                    showingReservationSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else if policy == "Borrowing Policy" {
                                // Custom button for the Borrowing policy
                                Button(action: {
                                    showingBorrowingSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else {
                                // Regular NavigationLink for other policies
                                NavigationLink(destination: PolicyDetailView(policyTitle: policy)) {
                                    policyItemView(title: policy)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6) // Increased vertical padding between items
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFineSettings) {
                FineSettingsView()
            }
            .sheet(isPresented: $showingReservationSettings) {
                ReservationSettingsView()
            }
            .sheet(isPresented: $showingBorrowingSettings) {
                BorrowingSettingsView()
            }
        }
        .accentColor(Color.primary(for: colorScheme))
    }
    
    // Extracted policy item view for reuse
    private func policyItemView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded)) // Increased text size
                .foregroundColor(Color.text(for: colorScheme))
                .padding(.vertical, 20) // Increased vertical padding for height
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.primary(for: colorScheme))
                .font(.system(size: 16, weight: .semibold)) // Increased icon size
        }
        .padding(.horizontal, 24) // Increased horizontal padding
        .background(
            RoundedRectangle(cornerRadius: 14) // Slightly larger corner radius
                .fill(colorScheme == .dark ?
                      Color(hex: ColorConstants.darkBackground).opacity(0.7) :
                      Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3) // Enhanced shadow for depth
        )
    }
}

// Fine Settings Modal View
struct FineSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State variables for the fine amount and grace period
    @State private var fineAmount: Double = 10
    @State private var gracePeriodDays: Double = 3
    
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
                        
                        Text("Fine Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.text(for: colorScheme))
                        
                        Spacer()
                        
                        // Save button
                        Button(action: {
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.primary(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            // Fine Amount Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Fine Amount Per Day")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("₹\(Int(fineAmount))")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style picker wheel effect
                                Slider(value: $fineAmount, in: 1...50, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("₹1")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("₹50")
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
                            
                            // Grace Period Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Grace Period")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("\(Int(gracePeriodDays)) Days")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style picker wheel effect
                                Slider(value: $gracePeriodDays, in: 0...14, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("0 Days")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("14 Days")
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
            .navigationBarHidden(true) // Hide the navigation bar completely
        }
    }
    
    // Save the settings (in a real app, you would persist these values)
    private func saveSettings() {
        // Here you would save the settings to your data store
        print("Fine amount set to: ₹\(Int(fineAmount)) per day")
        print("Grace period set to: \(Int(gracePeriodDays)) days")
    }
}

// Reservation Settings Modal View
struct ReservationSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State variables for reservation settings
    @State private var maxBooksReservable: Double = 5
    @State private var holdDurationDays: Double = 7
    
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
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.primary(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            // Maximum Books Reservable Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Maximum Books Reservable")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("\(Int(maxBooksReservable)) Books")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style slider
                                Slider(value: $maxBooksReservable, in: 1...10, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("1 Book")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("10 Books")
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
                            
                            // Hold Duration Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Hold Duration")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("\(Int(holdDurationDays)) Days")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style slider
                                Slider(value: $holdDurationDays, in: 1...30, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("1 Day")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("30 Days")
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
            .navigationBarHidden(true) // Hide the navigation bar completely
        }
    }
    
    // Save the settings (in a real app, you would persist these values)
    private func saveSettings() {
        // Here you would save the settings to your data store
        print("Maximum books reservable set to: \(Int(maxBooksReservable))")
        print("Hold duration set to: \(Int(holdDurationDays)) days")
    }
}

// Borrowing Settings Modal View
struct BorrowingSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State variables for borrowing settings
    @State private var maxBooksBorrowable: Double = 5
    @State private var reissuePeriodDays: Double = 14
    
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
                        
                        Text("Borrowing Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.text(for: colorScheme))
                        
                        Spacer()
                        
                        // Save button
                        Button(action: {
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.primary(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            // Maximum Books Borrowable Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Maximum Books Borrowable")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("\(Int(maxBooksBorrowable)) Books")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style slider
                                Slider(value: $maxBooksBorrowable, in: 1...15, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("1 Book")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("15 Books")
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
                            
                            // Reissue Period Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Reissue Period")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                Text("\(Int(reissuePeriodDays)) Days")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                // iOS-style slider
                                Slider(value: $reissuePeriodDays, in: 1...60, step: 1)
                                    .accentColor(Color.primary(for: colorScheme))
                                    .padding(.vertical, 10)
                                
                                HStack {
                                    Text("1 Day")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("60 Days")
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
            .navigationBarHidden(true) // Hide the navigation bar completely
        }
    }
    
    // Save the settings (in a real app, you would persist these values)
    private func saveSettings() {
        // Here you would save the settings to your data store
        print("Maximum books borrowable set to: \(Int(maxBooksBorrowable))")
        print("Reissue period set to: \(Int(reissuePeriodDays)) days")
    }
}

// Policy detail view
struct PolicyDetailView: View {
    var policyTitle: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background layer
            ReusableBackground(colorScheme: colorScheme)
            
            // Content layer
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(policyTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme))
                        .padding(.top, 10)
                    
                    DetailPlaceholderContent(title: policyTitle)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(policyTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
            }
        }
    }
}

// Placeholder content for policy details
struct DetailPlaceholderContent: View {
    var title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About this policy")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
            
            Text("This is the \(title.lowercased()) for the library management system. The complete details will be populated here. This section provides information about the rules and regulations related to this specific policy.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                .lineSpacing(4)
            
            // Policy sections
            PolicySection(title: "Section 1", content: "Details about section 1 of this policy will appear here.")
            PolicySection(title: "Section 2", content: "Details about section 2 of this policy will appear here.")
            PolicySection(title: "Section 3", content: "Details about section 3 of this policy will appear here.")
        }
        .padding(.vertical, 10)
    }
}

// Reusable policy section component
struct PolicySection: View {
    var title: String
    var content: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color.primary(for: colorScheme))
            
            Text(content)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                .lineSpacing(4)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ?
                      Color(hex: ColorConstants.darkBackground).opacity(0.7) :
                      Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

// Preview provider
struct ManagePoliciesAdmin_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ManagePoliciesAdmin()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            ManagePoliciesAdmin()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            FineSettingsView()
                .preferredColorScheme(.light)
                .previewDisplayName("Fine Settings Light")
            
            ReservationSettingsView()
                .preferredColorScheme(.light)
                .previewDisplayName("Reservation Settings Light")
            
            BorrowingSettingsView()
                .preferredColorScheme(.light)
                .previewDisplayName("Borrowing Settings Light")
        }
    }
}
