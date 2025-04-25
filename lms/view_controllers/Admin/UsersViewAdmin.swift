//
//  UsersViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI
import PhotosUI

// MARK: - Models
struct Librarian: Identifiable {
    let id = UUID()
    var name: String
    var image: UIImage?
    var email: String
    var phone: String
    var libraryCode: String
    var isActive: Bool = true
}

struct Member: Identifiable {
    let id = UUID()
    var name: String
    var image: UIImage?
    var email: String
    var phone: String
    var membershipId: String
    var isActive: Bool = true
}

// MARK: - ViewModel
class UsersViewModel: ObservableObject {
    @Published var selectedSegment = 0
    @Published var librarians: [Librarian] = []
    @Published var members: [Member] = []
    
    @Published var isShowingAddLibrarian = false
    @Published var isShowingAddMember = false
    @Published var newLibrarian = Librarian(name: "", image: nil, email: "", phone: "", libraryCode: "")
    @Published var newMember = Member(name: "", image: nil, email: "", phone: "", membershipId: "")
    @Published var selectedPhoto: PhotosPickerItem?
    
    // Track which user is being deactivated for confirmation
    @Published var librarianToDeactivate: UUID?
    @Published var memberToDeactivate: UUID?
    @Published var showDeactivateConfirmation = false
    
    func addLibrarian() {
        if !newLibrarian.name.isEmpty {
            if newLibrarian.libraryCode.isEmpty {
                newLibrarian.libraryCode = "LIB\(String(format: "%03d", librarians.count + 1))"
            }
            librarians.append(newLibrarian)
            resetLibrarianForm()
        }
    }
    
    func addMember() {
        if !newMember.name.isEmpty {
            if newMember.membershipId.isEmpty {
                newMember.membershipId = "MEM\(String(format: "%03d", members.count + 1))"
            }
            members.append(newMember)
            resetMemberForm()
        }
    }
    
    func confirmDeactivateLibrarian(_ id: UUID) {
        librarianToDeactivate = id
        memberToDeactivate = nil
        showDeactivateConfirmation = true
    }
    
    func confirmDeactivateMember(_ id: UUID) {
        memberToDeactivate = id
        librarianToDeactivate = nil
        showDeactivateConfirmation = true
    }
    
    func deactivateConfirmed() {
        if let id = librarianToDeactivate {
            if let index = librarians.firstIndex(where: { $0.id == id }) {
                librarians[index].isActive = false
            }
        } else if let id = memberToDeactivate {
            if let index = members.firstIndex(where: { $0.id == id }) {
                members[index].isActive = false
            }
        }
        
        // Reset the deactivation state
        librarianToDeactivate = nil
        memberToDeactivate = nil
    }
    
    func resetLibrarianForm() {
        newLibrarian = Librarian(name: "", image: nil, email: "", phone: "", libraryCode: "")
        selectedPhoto = nil
    }
    
    func resetMemberForm() {
        newMember = Member(name: "", image: nil, email: "", phone: "", membershipId: "")
        selectedPhoto = nil
    }
    
    func isValidPhoneNumber(_ phone: String) -> Bool {
        return phone.count == 10 && phone.allSatisfy { $0.isNumber }
    }
}

// MARK: - Main View
struct UsersViewAdmin: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                VStack(spacing: 0) {
                    Picker("User Type", selection: $viewModel.selectedSegment) {
                        Text("Librarians").tag(0)
                        Text("Members").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if viewModel.selectedSegment == 0 {
                        librariansListView
                    } else {
                        membersListView
                    }
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.selectedSegment == 0 {
                            viewModel.isShowingAddLibrarian = true
                        } else {
                            viewModel.isShowingAddMember = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.primary(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddLibrarian) {
                AddLibrarianView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingAddMember) {
                AddMemberView(viewModel: viewModel)
            }
            .confirmationDialog(
                "Confirm Deactivation",
                isPresented: $viewModel.showDeactivateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Deactivate", role: .destructive) {
                    viewModel.deactivateConfirmed()
                }
                Button("Cancel", role: .cancel) {
                    // Do nothing, just dismiss
                }
            } message: {
                if viewModel.librarianToDeactivate != nil {
                    Text("Are you sure you want to deactivate this librarian? They will no longer have access to the system.")
                } else if viewModel.memberToDeactivate != nil {
                    Text("Are you sure you want to deactivate this member? They will no longer have access to the system.")
                }
            }
        }
    }
    
    private var librariansListView: some View {
        List {
            ForEach(viewModel.librarians.filter { $0.isActive }) { librarian in
                LibrarianRow(librarian: librarian)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.confirmDeactivateLibrarian(librarian.id)
                        } label: {
                            Label("Deactivate", systemImage: "person.fill.xmark")
                        }
                        .tint(.red)
                    }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.librarians.filter({ $0.isActive }).isEmpty {
                emptyStateView(type: "Librarians")
            }
        }
    }
    
    private var membersListView: some View {
        List {
            ForEach(viewModel.members.filter { $0.isActive }) { member in
                MemberRow(member: member)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.confirmDeactivateMember(member.id)
                        } label: {
                            Label("Deactivate", systemImage: "person.fill.xmark")
                        }
                        .tint(.red)
                    }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.members.filter({ $0.isActive }).isEmpty {
                emptyStateView(type: "Members")
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView(type: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: type == "Librarians" ? "person.text.rectangle" : "person.2")
                .font(.system(size: 60))
                .foregroundColor(Color.primary(for: colorScheme).opacity(0.7))
                .padding(.top, 60)
            
            Text("No \(type) Yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color.text(for: colorScheme))
            
            Text("Tap the + button to add a new \(type.dropLast(1).lowercased())")
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row Views
struct LibrarianRow: View {
    let librarian: Librarian
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let image = librarian.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.primary(for: colorScheme))
                        .frame(width: 50, height: 50)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.primary(for: colorScheme).opacity(0.2), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(librarian.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
                
                Text(librarian.email)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                
                HStack(spacing: 8) {
                    Text(librarian.phone)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                    
                    Circle()
                        .fill(Color.text(for: colorScheme).opacity(0.4))
                        .frame(width: 4, height: 4)
                    
                    Text(librarian.libraryCode)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.primary(for: colorScheme))
                }
            }
            
            Spacer()
            
            Text("Staff")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primary(for: colorScheme).opacity(0.2))
                )
                .foregroundColor(Color.primary(for: colorScheme))
        }
        .padding(8)
    }
}

struct MemberRow: View {
    let member: Member
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let image = member.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.accent(for: colorScheme))
                        .frame(width: 50, height: 50)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.accent(for: colorScheme).opacity(0.2), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
                
                Text(member.email)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                
                HStack(spacing: 8) {
                    Text(member.phone)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                        .lineLimit(1)
                    
                    Circle()
                        .fill(Color.text(for: colorScheme).opacity(0.4))
                        .frame(width: 4, height: 4)
                    
                    Text(member.membershipId)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.accent(for: colorScheme))
                }
            }
            
            Spacer()
            
            Text("Member")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.accent(for: colorScheme).opacity(0.2))
                )
                .foregroundColor(Color.accent(for: colorScheme))
        }
        .padding(8)
    }
}

// MARK: - Add Librarian View
struct AddLibrarianView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusField: LibrarianField?
    
    enum LibrarianField {
        case name, email, phone, libraryCode
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemGroupedBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            photoSelector
                            
                            Text("Add Librarian Photo")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            formField(
                                title: "Full Name",
                                placeholder: "Enter full name",
                                text: $viewModel.newLibrarian.name,
                                field: .name
                            )
                            
                            formField(
                                title: "Email",
                                placeholder: "Enter email address",
                                text: $viewModel.newLibrarian.email,
                                field: .email
                            )
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            
                            phoneField(
                                title: "Phone Number",
                                placeholder: "Enter 10-digit phone number",
                                text: $viewModel.newLibrarian.phone,
                                field: .phone
                            )
                            
                            formField(
                                title: "Library Code",
                                placeholder: "Enter library code (optional)",
                                text: $viewModel.newLibrarian.libraryCode,
                                field: .libraryCode
                            )
                            .autocapitalization(.allCharacters)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Add Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetLibrarianForm()
                        dismiss()
                    }
                    .foregroundColor(Color.primary(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addLibrarian()
                        dismiss()
                    }
                    .foregroundColor(Color.primary(for: colorScheme))
                    .disabled(viewModel.newLibrarian.name.isEmpty ||
                              viewModel.newLibrarian.email.isEmpty ||
                              !viewModel.isValidPhoneNumber(viewModel.newLibrarian.phone))
                }
            }
        }
    }
    
    private var photoSelector: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
            ZStack {
                if let image = viewModel.newLibrarian.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primary(for: colorScheme), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(Color.primary(for: colorScheme))
                                .font(.system(size: 40))
                        )
                }
                
                Circle()
                    .fill(Color.primary(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    )
                    .offset(x: 40, y: 40)
            }
        }
        .onChange(of: viewModel.selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.newLibrarian.image = image
                }
            }
        }
    }
    
    @ViewBuilder
    private func formField(title: String, placeholder: String, text: Binding<String>, field: LibrarianField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                )
        }
    }
    
    @ViewBuilder
    private func phoneField(title: String, placeholder: String, text: Binding<String>, field: LibrarianField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .keyboardType(.numberPad)
                .onChange(of: text.wrappedValue) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 10 {
                        text.wrappedValue = String(filtered.prefix(10))
                    } else {
                        text.wrappedValue = filtered
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.isValidPhoneNumber(text.wrappedValue) || text.wrappedValue.isEmpty ?
                                Color.clear : Color.red.opacity(0.7), lineWidth: 1)
                )
            
            if !text.wrappedValue.isEmpty && !viewModel.isValidPhoneNumber(text.wrappedValue) {
                Text("Phone number must be exactly 10 digits")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Add Member View
struct AddMemberView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusField: MemberField?
    
    enum MemberField {
        case name, email, phone, membershipId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemGroupedBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            photoSelector
                            
                            Text("Add Member Photo")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            formField(
                                title: "Full Name",
                                placeholder: "Enter full name",
                                text: $viewModel.newMember.name,
                                field: .name
                            )
                            
                            formField(
                                title: "Email",
                                placeholder: "Enter email address",
                                text: $viewModel.newMember.email,
                                field: .email
                            )
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            
                            phoneField(
                                title: "Phone Number",
                                placeholder: "Enter 10-digit phone number",
                                text: $viewModel.newMember.phone,
                                field: .phone
                            )
                            
                            formField(
                                title: "Membership ID",
                                placeholder: "Enter membership ID (optional)",
                                text: $viewModel.newMember.membershipId,
                                field: .membershipId
                            )
                            .autocapitalization(.allCharacters)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetMemberForm()
                        dismiss()
                    }
                    .foregroundColor(Color.accent(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addMember()
                        dismiss()
                    }
                    .foregroundColor(Color.accent(for: colorScheme))
                    .disabled(viewModel.newMember.name.isEmpty ||
                              viewModel.newMember.email.isEmpty ||
                              !viewModel.isValidPhoneNumber(viewModel.newMember.phone))
                }
            }
        }
    }
    
    private var photoSelector: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
            ZStack {
                if let image = viewModel.newMember.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accent(for: colorScheme), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(Color.accent(for: colorScheme))
                                .font(.system(size: 40))
                        )
                }
                
                Circle()
                    .fill(Color.accent(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    )
                    .offset(x: 40, y: 40)
            }
        }
        .onChange(of: viewModel.selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.newMember.image = image
                }
            }
        }
    }
    
    @ViewBuilder
    private func formField(title: String, placeholder: String, text: Binding<String>, field: MemberField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                )
        }
    }
    
    @ViewBuilder
    private func phoneField(title: String, placeholder: String, text: Binding<String>, field: MemberField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            
            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .keyboardType(.numberPad)
                .onChange(of: text.wrappedValue) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 10 {
                        text.wrappedValue = String(filtered.prefix(10))
                    } else {
                        text.wrappedValue = filtered
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.isValidPhoneNumber(text.wrappedValue) || text.wrappedValue.isEmpty ?
                                Color.clear : Color.red.opacity(0.7), lineWidth: 1)
                )
            
            if !text.wrappedValue.isEmpty && !viewModel.isValidPhoneNumber(text.wrappedValue) {
                Text("Phone number must be exactly 10 digits")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Preview Provider
struct UsersViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UsersViewAdmin()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            UsersViewAdmin()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            AddLibrarianView(viewModel: UsersViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Add Librarian - Light")
            
            AddMemberView(viewModel: UsersViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Add Member - Dark")
        }
    }
}


