////
////  LibrarianRow.swift
////  lms
////
////  Created by Diptayan Jash on 25/04/25.
////
//
//import SwiftUI
//
//struct LibrarianRow: View {
//    let user: User
//    @ObservedObject var viewModel: UsersViewModel
//    @Environment(\.colorScheme) private var colorScheme
//
//    // Determine badge colors based on active status
//    private var badgeBackgroundColor: Color {
//        user.is_active ? Color.primary(for: colorScheme).opacity(0.2) : Color.red.opacity(0.2)
//    }
//    private var badgeForegroundColor: Color {
//        user.is_active ? Color.primary(for: colorScheme) : Color.red
//    }
//
//    var body: some View {
//        HStack(spacing: 16) {
//            // Profile Image (no changes needed here)
//            Group {
//                if let uiImage = viewModel.uiImage(from: user.profileImage) {
//                    Image(uiImage: uiImage)
//                        .resizable().scaledToFill()
//                        .frame(width: 50, height: 50).clipShape(Circle())
//                } else {
//                    Image(systemName: "person.circle.fill")
//                        .font(.system(size: 30))
//                        .foregroundColor(Color.primary(for: colorScheme))
//                        .frame(width: 50, height: 50)
//                }
//            }
//            .overlay(Circle().stroke(Color.primary(for: colorScheme).opacity(0.2), lineWidth: 1))
//
//            // User Details (no changes needed here)
//            VStack(alignment: .leading, spacing: 4) {
//                Text(user.name)
//                    .font(.system(size: 16, weight: .semibold, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme))
//                Text(user.email)
//                    .font(.system(size: 14, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//                Text("Library ID: \(user.library_id)")
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
//                    .foregroundColor(Color.primary(for: colorScheme).opacity(0.8))
//            }
//
//            Spacer()
//
//            // --- UPDATED BADGE ---
//            Text("Staff")
//                .font(.system(size: 10, weight: .semibold, design: .rounded))
//                .padding(.horizontal, 8).padding(.vertical, 4)
//                .background(Capsule().fill(badgeBackgroundColor)) // Use computed color
//                .foregroundColor(badgeForegroundColor)         // Use computed color
//            // --- END OF UPDATE ---
//        }
//        .padding(.vertical, 8)
//        // Fade out if inactive (optional visual cue)
//        // .opacity(user.is_active ? 1.0 : 0.6)
//    }
//}
