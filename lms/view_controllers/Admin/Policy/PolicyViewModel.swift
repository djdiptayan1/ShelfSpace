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
        fetchPolicy(libraryId: libraryId) { [weak self] policy in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentPolicy = policy
                if policy == nil {
                    print("❌ Failed to load policy data")
                    self.errorMessage = "Failed to load policy data"
                } else {
                    print("✅ Policy data loaded successfully")
                }
            }
        }
    }
    
    func savePolicy(policy: Policy, completion: @escaping (Bool) -> Void) {
        print("💾 Saving policy data...")
        showAnimation = true
        
        if let policyId = policy.policy_id {
            // Update existing policy
            updatePolicy(policyId: policyId, policyData: policy) { [weak self] success in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.saveSuccess = success
                    if success {
                        print("✅ Policy updated successfully")
                        self.currentPolicy = policy
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
                    self.saveSuccess = success
                    if success && policyId != nil {
                        print("✅ New policy created successfully")
                        var savedPolicy = policy
                        savedPolicy.policy_id = policyId
                        self.currentPolicy = savedPolicy
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
