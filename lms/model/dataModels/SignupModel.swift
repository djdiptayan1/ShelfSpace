//
//  SignupModel.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI
import Combine

class SignupModel: ObservableObject {
    // Step 1: Auth Information
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var selectedImage: UIImage?
    @Published var userId: UUID?
    
    // Validation states for inline feedback
    @Published var isEmailValid = true
    @Published var emailMessage = ""
    @Published var passwordStrength = PasswordStrength.empty
    @Published var passwordMessages: [String] = []
    @Published var isPasswordsMatching = true
    
    // Personal info validation states
    @Published var isNameValid = true
    @Published var nameMessage = ""
    @Published var isPhoneValid = true
    @Published var phoneMessage = ""
    @Published var isAgeValid = true
    @Published var ageMessage = ""
    @Published var isGenderValid = true
    @Published var genderMessage = ""
    
    // Step 2: Personal Information
    @Published var name = ""
    @Published var gender = ""
    @Published var age = ""
    @Published var phoneNumber = ""
    
    // Step 3: Interests
    @Published var selectedGenres: Set<String> = []
    
    // Step 4: Library Selection
    @Published var selectedLibraryId: String?
    @Published var selectedLibraryName: String = ""
    
    // Navigation and state
    @Published var currentStep = 1
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    // Password validation criteria
    enum PasswordStrength: Int {
        case empty = 0
        case veryWeak = 1
        case weak = 2
        case medium = 3
        case strong = 4
        
        var description: String {
            switch self {
            case .empty: return "Password strength"
            case .veryWeak: return "Very weak password"
            case .weak: return "Weak password"
            case .medium: return "Medium password"
            case .strong: return "Strong password"
            }
        }
        
        var color: Color {
            switch self {
            case .empty: return .gray
            case .veryWeak: return .red
            case .weak: return .orange
            case .medium: return .yellow
            case .strong: return .green
            }
        }
    }
    
    // Validation
    var isStep1Valid: Bool {
        !email.isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        passwordStrength.rawValue >= PasswordStrength.medium.rawValue
    }
    
    var isStep2Valid: Bool {
        !name.isEmpty &&
        !gender.isEmpty &&
        !age.isEmpty &&
        !phoneNumber.isEmpty &&
        isValidPhone(phoneNumber) &&
        Int(age) != nil &&
        Int(age)! >= 13
    }
    
    var isStep3Valid: Bool {
        !selectedGenres.isEmpty && selectedGenres.count <= 5
    }
    
    var isStep4Valid: Bool {
        selectedLibraryId != nil
    }
    
    @Published var destination: LoginDestination?
    @Published var showTwoFactorAuth: Bool = false
    
    // Add a specific flag for user already exists error
    @Published var isUserAlreadyExistsError = false
    
    func nextStep() {
        if currentStep < 4 {
            withAnimation {
                currentStep += 1
                resetError()
            }
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
                resetError()
            }
        }
    }
    
    func resetError() {
        showError = false
        errorMessage = ""
    }
    
    func createAuthAccount(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        isUserAlreadyExistsError = false
        
        LoginManager.shared.signUp(
            email: email,
            password: password
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let id):
                    self.userId = id
                    completion(true)
                case .failure(let error):
                    // Check specifically for user_already_exists error
                    if let authError = error as? LoginError, 
                       case .signupError(let message) = authError,
                       message.contains("User already registered") || message.contains("user_already_exists") {
                        self.isUserAlreadyExistsError = true
                        self.errorMessage = "This email is already registered. Please use a different email or log in."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showError = true
                    completion(false)
                }
            }
        }
    }
    
    func completeSignup(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        // Ensure library ID is provided
        guard let libraryId = selectedLibraryId, let userId = userId else {
            isLoading = false
            showError = true
            errorMessage = "Missing required information"
            completion(false)
            return
        }
        
        // Create user data object that matches our User model structure
        let userData: [String: Any] = [
            "user_id": userId.uuidString,
            "library_id": libraryId,
            "name": name,
            "email": email,
            "role": "member",
            "is_active": true,
            "gender": gender.lowercased(),
            "age": Int(age) ?? 0,
            "phone_number": phoneNumber,
            "interests": Array(selectedGenres),
            "borrowed_book_ids": [],
            "reserved_book_ids": [],
            "wishlist_book_ids": [],
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Debug print the user data
        print("Sending user data to database: \(userData)")
        
        // Save to Supabase users table
        insertUser(userData: userData) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    // Do not set destination here. Instead, showTwoFactorAuth will be set in LibrarySelectionView.
                } else {
                    self.showError = true
                    self.errorMessage = "Failed to save user data"
                }
                completion(success)
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[0-9+]{10,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
    
    func validateEmail() {
        if email.isEmpty {
            isEmailValid = true // Don't show error for empty field initially
            emailMessage = ""
        } else if !isValidEmail(email) {
            isEmailValid = false
            emailMessage = "Please enter a valid email address"
        } else {
            isEmailValid = true
            emailMessage = ""
        }
    }
    
    func validatePassword() {
        // Reset messages
        passwordMessages = []
        
        // If password is empty, don't show validation yet
        if password.isEmpty {
            passwordStrength = .empty
            return
        }
        
        // Check length
        let hasMinLength = password.count >= 6
        if !hasMinLength {
            passwordMessages.append("• At least 6 characters required")
        }
        
        // Check for uppercase letter
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        if !hasUppercase {
            passwordMessages.append("• At least one uppercase letter required")
        }
        
        // Check for lowercase letter
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        if !hasLowercase {
            passwordMessages.append("• At least one lowercase letter required")
        }
        
        // Check for number
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        if !hasDigit {
            passwordMessages.append("• At least one number required")
        }
        
        // Check for special character
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        if !hasSpecialChar {
            passwordMessages.append("• At least one special character required (!@#$%^&*)")
        }
        
        // Calculate strength
        let criteriaCount = [hasMinLength, hasUppercase, hasLowercase, hasDigit, hasSpecialChar].filter { $0 }.count
        switch criteriaCount {
        case 0...1:
            passwordStrength = .veryWeak
        case 2:
            passwordStrength = .weak
        case 3...4:
            passwordStrength = .medium
        case 5:
            passwordStrength = .strong
        default:
            passwordStrength = .empty
        }
    }
    
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            isPasswordsMatching = true // Don't show error for empty field
            return
        }
        isPasswordsMatching = password == confirmPassword
    }
    
    // Personal info validation methods
    func validateName() {
        if name.isEmpty {
            isNameValid = false
            nameMessage = "Name is required"
        } else if name.count < 2 {
            isNameValid = false
            nameMessage = "Name must be at least 2 characters"
        } else {
            isNameValid = true
            nameMessage = ""
        }
    }
    
    func validatePhone() {
        if phoneNumber.isEmpty {
            isPhoneValid = false
            phoneMessage = "Phone number is required"
        } else if phoneNumber.count != 10 {
            isPhoneValid = false
            phoneMessage = "Phone number must be exactly 10 digits"
        } else if !phoneNumber.allSatisfy({ $0.isNumber }) {
            isPhoneValid = false
            phoneMessage = "Phone number must contain only digits"
        } else {
            isPhoneValid = true
            phoneMessage = ""
        }
    }
    
    func validateAge() {
        if age.isEmpty {
            isAgeValid = false
            ageMessage = "Age is required"
        } else if let ageInt = Int(age) {
            if ageInt < 5 {
                isAgeValid = false
                ageMessage = "You must be at least 5 years old"
            } else {
                isAgeValid = true
                ageMessage = ""
            }
        } else {
            isAgeValid = false
            ageMessage = "Age must be a number"
        }
    }
    
    func validateGender() {
        if gender.isEmpty {
            isGenderValid = false
            genderMessage = "Gender is required"
        } else {
            isGenderValid = true
            genderMessage = ""
        }
    }
}
