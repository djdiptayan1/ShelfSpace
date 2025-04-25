//
//  CustomTextField.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//

import Foundation
import SwiftUI
// Add this parameter to CustomTextField
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let iconName: String
    var isSecure: Bool = false
    var showSecureToggle: Bool = false
    var secureToggleAction: (() -> Void)? = nil
    @FocusState var focusState: AuthFieldType?
    let colorScheme: ColorScheme
    var keyboardType: UIKeyboardType = .default // Keep this parameter
    let fieldType: AuthFieldType
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(Color.accent(for: colorScheme))
                .frame(width: 24)
            
            // Text input
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(fieldType == .password ? .password : .none)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(fieldType == .email ? .emailAddress : .none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(keyboardType) // Use the parameter here
                }
            }
            .font(.system(size: 16, design: .rounded))
            
            if showSecureToggle {
                Button(action: {
                    secureToggleAction?()
                }) {
                    Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.5))
                }
            }
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
}
