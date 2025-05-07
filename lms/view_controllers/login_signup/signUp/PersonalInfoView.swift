//
//  PersonalInfoView.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI

struct PersonalInfoView: View {
    @ObservedObject var viewModel: SignupModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: PersonalFieldType?
    @State private var isAgePickerPresented = false

    enum PersonalFieldType {
        case name
        case gender
        case age
        case phone
    }

    private let genderOptions = ["Male", "Female", "Prefer not to say"]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Personal Information")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))

                Text("Tell us a bit about yourself")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    .padding(.bottom, 10)

                // Form Fields
                VStack(spacing: 16) {
                    // Name Field with validation
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            text: $viewModel.name,
                            placeholder: "Full Name",
                            iconName: "person.fill",
                            isSecure: false,
                            colorScheme: colorScheme,
                            fieldType: .name
                        )
                        .focused($focusedField, equals: .name)
                        .onChange(of: viewModel.name) { _ in
                            viewModel.resetError()
                            viewModel.validateName()
                        }
                        
                        if !viewModel.isNameValid {
                            Text(viewModel.nameMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }

                    // Gender Selection with validation
                    VStack(alignment: .leading, spacing: 4) {
                        Menu {
                            ForEach(genderOptions, id: \.self) { option in
                                Button(action: {
                                    viewModel.gender = option
                                    viewModel.resetError()
                                    viewModel.validateGender()
                                }) {
                                    Text(option)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(Color.accent(for: colorScheme))
                                    .font(.system(size: 16))

                                Text(viewModel.gender.isEmpty ? "Select Gender" : viewModel.gender)
                                    .foregroundColor(viewModel.gender.isEmpty ? Color.text(for: colorScheme).opacity(0.5) : Color.text(for: colorScheme))
                                    .font(.system(size: 16))

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.isGenderValid ? Color.text(for: colorScheme).opacity(0.1) : Color.red, lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.text(for: colorScheme).opacity(0.03))
                                    )
                            )
                        }
                        .onAppear {
                            viewModel.validateGender()
                        }
                        
                        if !viewModel.isGenderValid {
                            Text(viewModel.genderMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }

                    // Age Field with validation
                    VStack(alignment: .leading, spacing: 4) {
                        Menu {
                            ForEach(4 ... 90, id: \.self) { age in
                                Button(action: {
                                    viewModel.age = "\(age)"
                                    viewModel.resetError()
                                    viewModel.validateAge()
                                }) {
                                    Text("\(age)")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(Color.accent(for: colorScheme))
                                    .font(.system(size: 16))

                                Text(viewModel.age.isEmpty ? "Select Age" : viewModel.age)
                                    .foregroundColor(viewModel.age.isEmpty ? Color.text(for: colorScheme).opacity(0.5) : Color.text(for: colorScheme))
                                    .font(.system(size: 16))

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.primary(for: colorScheme))
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.isAgeValid ? Color.text(for: colorScheme).opacity(0.1) : Color.red, lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.text(for: colorScheme).opacity(0.03))
                                    )
                            )
                        }
                        .onAppear {
                            viewModel.validateAge()
                        }
                        
                        if !viewModel.isAgeValid {
                            Text(viewModel.ageMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }

                    // Phone Number Field with validation and input limiting
                    VStack(alignment: .leading, spacing: 4) {
                        CustomTextField(
                            text: $viewModel.phoneNumber,
                            placeholder: "Phone Number (10 digits)",
                            iconName: "phone.fill",
                            isSecure: false,
                            colorScheme: colorScheme,
                            keyboardType: .phonePad,
                            fieldType: .phone
                        )
                        .focused($focusedField, equals: .phone)
                        .onChange(of: viewModel.phoneNumber) { newValue in
                            viewModel.resetError()
                            
                            // Filter out non-numeric characters
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                viewModel.phoneNumber = filtered
                            }
                            
                            // Limit to 10 digits
                            if viewModel.phoneNumber.count > 10 {
                                viewModel.phoneNumber = String(viewModel.phoneNumber.prefix(10))
                            }
                            
                            viewModel.validatePhone()
                        }
                        
                        if !viewModel.isPhoneValid {
                            Text(viewModel.phoneMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 8)
                        }
                    }
                }
                .padding(.horizontal, 24)

                if viewModel.showError {
                    Text(viewModel.errorMessage)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }

                Button {
                    withAnimation {
                        // Validate all fields
                        viewModel.validateName()
                        viewModel.validateGender()
                        viewModel.validateAge()
                        viewModel.validatePhone()
                        
                        if viewModel.isNameValid && viewModel.isGenderValid && 
                           viewModel.isAgeValid && viewModel.isPhoneValid {
                            viewModel.nextStep()
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary(for: colorScheme))

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 54)
                    .padding(.horizontal, 24)
                }
                .disabled(viewModel.isLoading)
                .opacity(!viewModel.name.isEmpty && !viewModel.gender.isEmpty && 
                         !viewModel.age.isEmpty && !viewModel.phoneNumber.isEmpty ? 1 : 0.7)

                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}
