import SwiftUI

struct SignupContainerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SignupModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                VStack {
                                        // Current Step View
                    Group {
                        switch viewModel.currentStep {
                        case 1:
                            signupView(viewModel: viewModel)
                        case 2:
                            PersonalInfoView(viewModel: viewModel)
                        case 3:
                            InterestsView(viewModel: viewModel)
                        case 4:
                            LibrarySelectionView(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .navigationBarTitle("Sign Up", displayMode: .inline)
            .navigationBarBackButtonHidden(false)
            .fullScreenCover(item: $viewModel.destination) { destination in
                switch destination {
                case .admin: AdminTabbar()
                case .librarian: LibrarianTabbar()
                case .member: UserTabbar()
                }
            }
            .sheet(isPresented: $viewModel.showTwoFactorAuth) {
                TwoFactorAuthView(email: viewModel.email) { verified in
                    if verified {
                        viewModel.destination = .member
                        viewModel.showTwoFactorAuth = false
                    }
                }
                .interactiveDismissDisabled(true)
            }
        }
    }
}

#Preview {
    SignupContainerView()
} 
