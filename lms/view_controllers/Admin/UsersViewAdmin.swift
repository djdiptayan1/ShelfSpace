//
//  UsersViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct Librarian: Identifiable {
    let id = UUID()
    var name: String
    var image: UIImage?
    var email: String
    var phone: String
    var libraryCode: String
    var isActive: Bool = true
}

struct UsersViewAdmin: View {
    @State private var selectedSegment = 0
    @State private var librarians: [Librarian] = [
        Librarian(name: "John Doe", image: nil, email: "john@library.com", phone: "1234567890", libraryCode: "LIB001"),
        Librarian(name: "Jane Smith", image: nil, email: "jane@library.com", phone: "0987654321", libraryCode: "LIB002"),
        Librarian(name: "Robert Johnson", image: nil, email: "robert@library.com", phone: "1122334455", libraryCode: "LIB003"),
        Librarian(name: "Emily Davis", image: nil, email: "emily@library.com", phone: "5566778899", libraryCode: "LIB004")
    ]
    
    @State private var isShowingAddLibrarian = false
    @State private var newLibrarian = Librarian(name: "", image: nil, email: "", phone: "", libraryCode: "")
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        NavigationStack { // Changed to NavigationStack for iOS 16+
            ZStack {
                // Main Users View
                VStack {
                    // Header with title and add button
                    HStack {
                        Text("Users")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingAddLibrarian = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    
                    // Segmented control
                    Picker("", selection: $selectedSegment) {
                        Text("Librarian").tag(0)
                        Text("Members").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Content based on selection
                    if selectedSegment == 0 {
                        List {
                            ForEach(librarians) { librarian in
                                if librarian.isActive {
                                    LibrarianRow(librarian: librarian)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deactivateLibrarian(librarian.id)
                                            } label: {
                                                Label("Deactivate", systemImage: "person.fill.xmark")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                        }
                        .listStyle(.plain)
                    } else {
                        // Members view placeholder
                        Text("Members will be displayed here")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Add Librarian Overlay
                if isShowingAddLibrarian {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isShowingAddLibrarian = false
                        }
                    
                    VStack(spacing: 0) {
                        // Top bar with Cancel, Title, and Done
                        HStack {
                            Button("Cancel") {
                                isShowingAddLibrarian = false
                                resetForm()
                            }
                            .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("New Librarian")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Done") {
                                if !newLibrarian.name.isEmpty {
                                    librarians.append(newLibrarian)
                                    isShowingAddLibrarian = false
                                    resetForm()
                                }
                            }
                            .foregroundColor(.blue)
                            .disabled(newLibrarian.name.isEmpty)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                // Photo Section
                                VStack(spacing: 10) {
                                    if let image = newLibrarian.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.gray)
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                    }
                                    
                                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                        Text("Add Photo")
                                            .foregroundColor(.blue)
                                    }
                                    .onChange(of: selectedPhoto) { newItem in
                                        Task {
                                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                newLibrarian.image = image
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 20)
                                
                                // Form fields
                                Group {
                                    TextField("Librarian Name", text: $newLibrarian.name)
                                    TextField("Email Id", text: $newLibrarian.email)
                                        .keyboardType(.emailAddress)
                                    TextField("Phone Number", text: $newLibrarian.phone)
                                        .keyboardType(.phonePad)
                                    TextField("Library Code", text: $newLibrarian.libraryCode)
                                }
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width - 40, height: 500)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
            .onAppear {
                print("UsersViewAdmin appeared")
            }
        }
    }
    
    private func deactivateLibrarian(_ id: UUID) {
        if let index = librarians.firstIndex(where: { $0.id == id }) {
            librarians[index].isActive = false
        }
    }
    
    private func resetForm() {
        newLibrarian = Librarian(name: "", image: nil, email: "", phone: "", libraryCode: "")
        selectedPhoto = nil
    }
}

struct LibrarianRow: View {
    let librarian: Librarian
    
    var body: some View {
        HStack {
            if let image = librarian.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(librarian.name)
                    .font(.headline)
                Text(librarian.libraryCode)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct UsersView_Previews: PreviewProvider {
    static var previews: some View {
        UsersViewAdmin()
            .environmentObject(ThemeManager())
    }
}

