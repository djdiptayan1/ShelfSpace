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
                    // No policy found, create a default one with correct library ID
                    do {
                        let libraryIdString = try KeychainManager.shared.getLibraryId()
                        let libraryId = UUID(uuidString: libraryIdString)!
                        let defaultPolicy = Policy(
                            library_id: libraryId,
                            max_borrow_days: 14,
                            fine_per_day: 1,
                            max_books_per_user: 4,
                            reservation_expiry_days: 1
                        )
                        self.currentPolicy = defaultPolicy
                        self.errorMessage = nil
                        print("⚠️ No existing policy found - initialized with default values")
                    } catch {
                        self.errorMessage = "Failed to get library ID"
                    }
                }
            }
        }
    }
    
    func savePolicy(policy: Policy, completion: @escaping (Bool) -> Void) {
        print("💾 Saving policy data...")
        isLoading = true
        showAnimation = true

        do {
            let libraryIdString = try KeychainManager.shared.getLibraryId()
            let libraryId = UUID(uuidString: libraryIdString)!
            var policyToSave = policy
            policyToSave.library_id = libraryId

            if let policyId = policy.policy_id {
                // Update existing policy
                updatePolicy(policyId: policyId, policyData: policyToSave) { [weak self] success in
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
                // Try to insert, but if it fails with "already exists", fetch and update
                insertPolicy(policyData: policyToSave) { [weak self] success, policyId in
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
                            self.showAnimation = false
                            completion(true)
                        } else {
                            // Check for "already exists" error
                            if let errorMsg = self.errorMessage, errorMsg.contains("already exists") {
                                // Fetch the existing policy and update it
                                fetchPolicy(libraryId: libraryId) { existingPolicy in
                                    if let existingPolicy = existingPolicy {
                                        self.savePolicy(policy: existingPolicy, completion: completion)
                                    } else {
                                        self.errorMessage = "Failed to fetch existing policy for update"
                                        self.showAnimation = false
                                        completion(false)
                                    }
                                }
                            } else {
                                print("❌ Failed to create policy")
                                self.errorMessage = "Failed to create policy"
                                self.showAnimation = false
                                completion(false)
                            }
                        }
                    }
                }
            }
        } catch {
            self.isLoading = false
            self.showAnimation = false
            self.errorMessage = "Failed to get library ID"
            completion(false)
        }
    }
}
