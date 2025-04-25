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

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]

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
                    // Name Field
                    CustomTextField(
                        text: $viewModel.name,
                        placeholder: "Full Name",
                        iconName: "person.fill",
                        isSecure: false,
                        colorScheme: colorScheme,
                        fieldType: .name
                    )
                    .focused($focusedField, equals: .name)

                    // Gender Selection
                    Menu {
                        ForEach(genderOptions, id: \.self) { option in
                            Button(action: {
                                viewModel.gender = option
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
                                .stroke(Color.text(for: colorScheme).opacity(0.1), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.text(for: colorScheme).opacity(0.03))
                                )
                        )
                    }

                    // Age Field
//                    CustomTextField(
//                        text: $viewModel.age,
//                        placeholder: "Age",
//                        iconName: "number",
//                        isSecure: false,
//                        colorScheme: colorScheme,
//                        keyboardType: .numberPad,
//                        fieldType: .age,
//                    )
//                    .focused($focusedField, equals: .age)

                    Menu {
                        ForEach(4 ... 90, id: \.self) { age in
                            Button(action: {
                                viewModel.age = "\(age)"
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
                                .stroke(Color.text(for: colorScheme).opacity(0.1), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.text(for: colorScheme).opacity(0.03))
                                )
                        )
                    }

                    // Phone Number Field
                    CustomTextField(
                        text: $viewModel.phoneNumber,
                        placeholder: "Phone Number",
                        iconName: "phone.fill",
                        isSecure: false,
                        colorScheme: colorScheme,
                        keyboardType: .phonePad,
                        fieldType: .phone
                    )
                    .focused($focusedField, equals: .phone)
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
                        if viewModel.isStep2Valid {
                            viewModel.nextStep()
                        } else {
                            viewModel.errorMessage = "Please fill in all fields correctly."
                            viewModel.showError = true
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
                .disabled(viewModel.isLoading || !viewModel.isStep2Valid)
                .opacity(viewModel.isStep2Valid ? 1 : 0.7)

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
