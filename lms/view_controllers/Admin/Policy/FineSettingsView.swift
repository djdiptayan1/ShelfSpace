//
//  FineSettingsView.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
import SwiftUI
import DotLottie
// Update for FineSettingsView
struct FineSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var policyViewModel: PolicyViewModel
    
    // State variables for UI
    @State private var fineAmount: Double = 10
//    @State private var gracePeriodDays: Double = 3
    @State private var showingSaveAlert: Bool = false
    
    // Initialize from ViewModel
    init(viewModel: PolicyViewModel? = nil) {
        if let vm = viewModel {
            _fineAmount = State(initialValue: Double(truncating: vm.currentPolicy?.fine_per_day as? NSNumber ?? 10 as NSNumber))
            // If you had grace period in your model, you'd set it here too
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
                        
                        Text("Fine Settings")
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
//                            VStack(alignment: .leading, spacing: 15) {
//                                Text("Grace Period")
//                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
//                                    .foregroundColor(Color.text(for: colorScheme))
//                                
//                                Text("\(Int(gracePeriodDays)) Days")
//                                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                                    .foregroundColor(Color.primary(for: colorScheme))
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .padding(.vertical, 10)
//                                
//                                // iOS-style picker wheel effect
//                                Slider(value: $gracePeriodDays, in: 0...14, step: 1)
//                                    .accentColor(Color.primary(for: colorScheme))
//                                    .padding(.vertical, 10)
//                                
//                                HStack {
//                                    Text("0 Days")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                    
//                                    Spacer()
//                                    
//                                    Text("14 Days")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                }
//                            }
//                            .padding(20)
//                            .background(
//                                RoundedRectangle(cornerRadius: 15)
//                                    .fill(colorScheme == .dark ?
//                                          Color(hex: ColorConstants.darkBackground).opacity(0.7) :
//                                          Color.white.opacity(0.9))
//                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
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
                        message: Text("Fine settings have been updated."),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .overlay(
                Group {
                    if policyViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
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
        .onAppear {
            // Set initial values from ViewModel
            if let policy = policyViewModel.currentPolicy {
                fineAmount = Double(truncating: policy.fine_per_day as NSNumber)
                // If you had grace period in your model, you'd set it here
            }
        }
    }
    
    private func saveSettings() {
        // Using fineAmount and gracePeriodDays for save action
        if let currentPolicy = policyViewModel.currentPolicy {
            var updatedPolicy = currentPolicy
            updatedPolicy.fine_per_day = Decimal(fineAmount)
            
            policyViewModel.savePolicy(policy: updatedPolicy) { success in
                if success {
                    showingSaveAlert = true
                }
            }
        }
    }
}

//
//struct FineSettingsView: View {
//    @Environment(\.colorScheme) private var colorScheme
//    @Environment(\.presentationMode) var presentationMode
//    
//    // State variables for the fine amount and grace period
//    @State private var fineAmount: Double = 10
//    @State private var gracePeriodDays: Double = 3
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background layer
//                ReusableBackground(colorScheme: colorScheme)
//                
//                // Content layer
//                VStack {
//                    // Header
//                    HStack {
//                        // iOS native style cancel button
//                        Button(action: {
//                            presentationMode.wrappedValue.dismiss()
//                        }) {
//                            Text("Cancel")
//                                .font(.system(size: 17, weight: .regular))
//                                .foregroundColor(.red)
//                        }
//                        
//                        Spacer()
//                        
//                        Text("Fine Settings")
//                            .font(.system(size: 17, weight: .semibold))
//                            .foregroundColor(Color.text(for: colorScheme))
//                        
//                        Spacer()
//                        
//                        // Save button
//                        Button(action: {
//                            saveSettings()
//                            presentationMode.wrappedValue.dismiss()
//                        }) {
//                            Text("Save")
//                                .font(.system(size: 17, weight: .semibold))
//                                .foregroundColor(Color.primary(for: colorScheme))
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 16)
//                    .padding(.bottom, 10)
//                    
//                    ScrollView {
//                        VStack(alignment: .leading, spacing: 30) {
//                            // Fine Amount Card
//                            VStack(alignment: .leading, spacing: 15) {
//                                Text("Fine Amount Per Day")
//                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
//                                    .foregroundColor(Color.text(for: colorScheme))
//                                
//                                Text("₹\(Int(fineAmount))")
//                                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                                    .foregroundColor(Color.primary(for: colorScheme))
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .padding(.vertical, 10)
//                                
//                                // iOS-style picker wheel effect
//                                Slider(value: $fineAmount, in: 1...50, step: 1)
//                                    .accentColor(Color.primary(for: colorScheme))
//                                    .padding(.vertical, 10)
//                                
//                                HStack {
//                                    Text("₹1")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                    
//                                    Spacer()
//                                    
//                                    Text("₹50")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                }
//                            }
//                            .padding(20)
//                            .background(
//                                RoundedRectangle(cornerRadius: 15)
//                                    .fill(colorScheme == .dark ?
//                                          Color(hex: ColorConstants.darkBackground).opacity(0.7) :
//                                          Color.white.opacity(0.9))
//                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                            )
//                            
//                            // Grace Period Card
//                            VStack(alignment: .leading, spacing: 15) {
//                                Text("Grace Period")
//                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
//                                    .foregroundColor(Color.text(for: colorScheme))
//                                
//                                Text("\(Int(gracePeriodDays)) Days")
//                                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                                    .foregroundColor(Color.primary(for: colorScheme))
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .padding(.vertical, 10)
//                                
//                                // iOS-style picker wheel effect
//                                Slider(value: $gracePeriodDays, in: 0...14, step: 1)
//                                    .accentColor(Color.primary(for: colorScheme))
//                                    .padding(.vertical, 10)
//                                
//                                HStack {
//                                    Text("0 Days")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                    
//                                    Spacer()
//                                    
//                                    Text("14 Days")
//                                        .font(.system(size: 14))
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
//                                }
//                            }
//                            .padding(20)
//                            .background(
//                                RoundedRectangle(cornerRadius: 15)
//                                    .fill(colorScheme == .dark ?
//                                          Color(hex: ColorConstants.darkBackground).opacity(0.7) :
//                                          Color.white.opacity(0.9))
//                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                            )
//                        }
//                        .padding(.horizontal, 20)
//                        .padding(.bottom, 40)
//                    }
//                }
//            }
//            .navigationBarHidden(true) // Hide the navigation bar completely
//        }
//    }
//    
//    // Save the settings (in a real app, you would persist these values)
//    private func saveSettings() {
//        // Here you would save the settings to your data store
//        print("Fine amount set to: ₹\(Int(fineAmount)) per day")
//        print("Grace period set to: \(Int(gracePeriodDays)) days")
//    }
//}
