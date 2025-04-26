//
//  BorrowingSettingsView.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
import SwiftUI
import DotLottie

struct BorrowingSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var policyViewModel: PolicyViewModel
    
    // State variables for borrowing settings
    @State private var maxBooksBorrowable: Double = 5
    @State private var reissuePeriodDays: Double = 14
    @State private var showingSaveAlert: Bool = false
    
    init(viewModel: PolicyViewModel? = nil) {
        if let vm = viewModel {
            _maxBooksBorrowable = State(initialValue: Double(vm.currentPolicy?.max_books_per_user ?? 5))
            _reissuePeriodDays = State(initialValue: Double(vm.currentPolicy?.max_borrow_days ?? 14))
        }
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
                        
                        Text("Borrowing Settings")
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
            }
            .navigationBarHidden(true) // Hide the navigation bar completely
            .onAppear {
                // Load current policy values from the view model
                if let policy = policyViewModel.currentPolicy {
                    maxBooksBorrowable = Double(policy.max_books_per_user)
                    reissuePeriodDays = Double(policy.max_borrow_days)
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
            .alert(isPresented: $showingSaveAlert) {
                Alert(
                    title: Text(policyViewModel.saveSuccess ? "Success" : "Error"),
                    message: Text(policyViewModel.saveSuccess ? "Borrowing settings saved successfully." : "Failed to save settings. Please try again."),
                    dismissButton: .default(Text("OK")) {
                        if policyViewModel.saveSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    // Save the settings using PolicyViewModel
    private func saveSettings() {
        if var updatedPolicy = policyViewModel.currentPolicy {
            updatedPolicy.max_books_per_user = Int(maxBooksBorrowable)
            updatedPolicy.max_borrow_days = Int(reissuePeriodDays)
            
            policyViewModel.savePolicy(policy: updatedPolicy) { success in
                self.showingSaveAlert = true
            }
        }
    }
}
