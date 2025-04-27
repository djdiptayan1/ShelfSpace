//
//  PolicyViewModel.swift
//  lms
//
//  Created by Diptayan Jash on 26/04/25.
//

import Foundation
import SwiftUI
import Combine
import DotLottie

// Let's also add a PolicyViewModel to support the API operations
class PolicyViewModel: ObservableObject {
    @Published var currentPolicy: Policy?
    @Published var isLoading: Bool = false
    @Published var saveSuccess: Bool = false
    @Published var errorMessage: String?
    @Published var showAnimation: Bool = false
    let libraryId: UUID
    
    init(libraryId: UUID) {
        self.libraryId = libraryId
    }
    
    func loadPolicy() {
        print("🔄 Loading policy data...")
        isLoading = true
        fetchPolicy(libraryId: libraryId) { [weak self] policy in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let policy = policy {
                    self.currentPolicy = policy
                    self.errorMessage = nil
                    print("✅ Policy data loaded successfully")
                } else {
                    print("⚠️ No existing policy found - will create new one when saved")
                    // Don't set error message here as it's not really an error
                    // Just means we need to create a new policy
                }
            }
        }
    }
    
    func savePolicy(policy: Policy, completion: @escaping (Bool) -> Void) {
        print("💾 Saving policy data...")
        isLoading = true
        showAnimation = true
        
        if let policyId = policy.policy_id {
            // Update existing policy
            updatePolicy(policyId: policyId, policyData: policy) { [weak self] success in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.saveSuccess = success
                    if success {
                        print("✅ Policy updated successfully")
                        self.currentPolicy = policy
                        self.errorMessage = nil
                    } else {
                        print("❌ Failed to update policy")
                        self.errorMessage = "Failed to update policy"
                    }
                    self.showAnimation = false
                    completion(success)
                }
            }
        } else {
            // Create new policy
            insertPolicy(policyData: policy) { [weak self] success, policyId in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.saveSuccess = success
                    if success && policyId != nil {
                        print("✅ New policy created successfully")
                        var savedPolicy = policy
                        savedPolicy.policy_id = policyId
                        self.currentPolicy = savedPolicy
                        self.errorMessage = nil
                    } else {
                        print("❌ Failed to create policy")
                        self.errorMessage = "Failed to create policy"
                    }
                    self.showAnimation = false
                    completion(success)
                }
            }
        }
    }
}
