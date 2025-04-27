import Foundation
import SwiftUI
import DotLottie

struct ManagePoliciesAdmin: View {
    // Policy items to display in the list
    private let policyItems = [
        "Fines and Overdue Items",
        "Reservation Policy",
        "Borrowing Policy",
        "Privacy Policy"
    ]
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: PolicyViewModel
    @State private var showingFineSettings = false
    @State private var showingReservationSettings = false
    @State private var showingBorrowingSettings = false
    @State private var showingLoadingError = false
    
    // Initialize with a default library ID
    init(libraryId: UUID = UUID(uuidString: "2f4e9c45-b0eb-4850-bd7d-aad0e1259128")!) {
        // Use _viewModel to set the StateObject during init
        _viewModel = StateObject(wrappedValue: PolicyViewModel(libraryId: libraryId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background layer
                ReusableBackground(colorScheme: colorScheme)
                
                // Content layer
                VStack(spacing: 16) { // Increased spacing between items
                    Text("Library Policies")
                        .font(.system(size: 28, weight: .bold, design: .rounded)) // Increased heading size
                        .foregroundColor(Color.text(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 25) // Increased top padding
                        .padding(.bottom, 10) // Added bottom padding
    
                    // Policy items list
                    ForEach(policyItems, id: \.self) { policy in
                        Group {
                            if policy == "Fines and Overdue Items" {
                                // Custom button for the Fines policy
                                Button(action: {
                                    showingFineSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else if policy == "Reservation Policy" {
                                // Custom button for the Reservation policy
                                Button(action: {
                                    showingReservationSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else if policy == "Borrowing Policy" {
                                // Custom button for the Borrowing policy
                                Button(action: {
                                    showingBorrowingSettings = true
                                }) {
                                    policyItemView(title: policy)
                                }
                            } else {
                                // For Privacy Policy, use a regular Button as placeholder
                                Button(action: {
                                    // Action for privacy policy
                                    print("Privacy Policy selected")
                                }) {
                                    policyItemView(title: policy)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6) // Increased vertical padding between items
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // View model is already initialized with libraryId
                viewModel.loadPolicy()
            }
            .sheet(isPresented: $showingFineSettings) {
                FineSettingsView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingReservationSettings) {
                ReservationSettingsView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingBorrowingSettings) {
                BorrowingSettingsView()
                    .environmentObject(viewModel)
            }
            .alert(isPresented: $showingLoadingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.errorMessage) { error in
                showingLoadingError = error != nil
            }
        }
        .accentColor(Color.primary(for: colorScheme))
    }
    
    // Extracted policy item view for reuse
    private func policyItemView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded)) // Increased text size
                .foregroundColor(Color.text(for: colorScheme))
                .padding(.vertical, 20) // Increased vertical padding for height
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.primary(for: colorScheme))
                .font(.system(size: 16, weight: .semibold)) // Increased icon size
        }
        .padding(.horizontal, 24) // Increased horizontal padding
        .background(
            RoundedRectangle(cornerRadius: 14) // Slightly larger corner radius
                .fill(colorScheme == .dark ?
                      Color(hex: ColorConstants.darkBackground).opacity(0.7) :
                      Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3) // Enhanced shadow for depth
        )
    }
}
