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
    
    // Validation
    var isStep1Valid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        isValidEmail(email) &&
        password.count >= 4
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
    
    @Published var destination: LoginState.LoginDestination?
    
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
        
        LoginManager.shared.signUp(
            email: email,
            password: password,
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    func completeSignup(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        // Ensure library ID is provided
        guard let libraryId = selectedLibraryId else {
            isLoading = false
            showError = true
            errorMessage = "No library selected"
            completion(false)
            return
        }
        
        // Create user data object
        let userData: [String: AnyEncodable] = [
            "user_id": AnyEncodable(UUID().uuidString), // Generate a new UUID for the user
            "library_id": AnyEncodable(libraryId),
            "name": AnyEncodable(name),
            "email": AnyEncodable(email),
            "role": AnyEncodable("member"),
            "is_active": AnyEncodable(true),
            "gender": AnyEncodable(gender),
            "age": AnyEncodable(Int(age) ?? 0),
            "phone_number": AnyEncodable(phoneNumber),
            "interests": AnyEncodable(Array(selectedGenres))
        ]
        
        // Save to Supabase users table
        insertUser(userData: userData) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    // Set the destination based on the role from userData
                    if let roleString = userData["role"]?.wrappedValue as? String {
                        switch roleString.lowercased() {
                        case "admin":
                            self.destination = .admin
                        case "librarian":
                            self.destination = .librarian
                        case "member":
                            self.destination = .member
                        default:
                            self.destination = .member
                        }
                    } else {
                        self.destination = .member
                    }
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
}
