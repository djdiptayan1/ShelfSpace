//
//  MemberRow.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import SwiftUI

struct MemberRow: View {
    let user: User
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.colorScheme) private var colorScheme

    // Determine badge colors based on active status
    private var badgeBackgroundColor: Color {
        user.is_active ?? false ? Color.accent(for: colorScheme).opacity(0.2) : Color.red.opacity(0.2)
    }
    
    private var badgeForegroundColor: Color {
        user.is_active ?? false ? Color.accent(for: colorScheme) : Color.red
    }
    
    // Status text is now dynamic based on active status
    private var statusText: String {
        user.is_active ?? false ? "Active" : "Inactive"
    }

    private var statusColor: Color {
        user.is_active ?? false ? Color.green : Color.red
    }

    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            Group {
                if let uiImage = viewModel.uiImage(from: user.profileImage) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 50, height: 50).clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.accent(for: colorScheme))
                        .frame(width: 50, height: 50)
                }
            }
            .overlay(Circle().stroke(Color.accent(for: colorScheme).opacity(0.2), lineWidth: 1))

            // User Details
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
                Text(user.email)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                Text("Library ID: \(user.library_id)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.accent(for: colorScheme).opacity(0.8))
            }

            Spacer()

            // Dynamic status badge
            Text(statusText)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(statusColor.opacity(0.2)))
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 8)
        // Apply a slight opacity reduction if user is inactive
        .opacity(user.is_active ?? false ? 1.0 : 0.7)
        .swipeActions(edge: .trailing) {
            Button {
                viewModel.toggleUserActiveStatus(user)
            } label: {
                Label(
                    user.is_active ?? false ? "Deactivate" : "Activate",
                    systemImage: user.is_active ?? false ? "person.fill.xmark" : "person.fill.checkmark"
                )
            }
            .tint(user.is_active ?? false ? .red : .green)
        }
    }
}
