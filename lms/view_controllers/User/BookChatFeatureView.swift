//  BookChatFeatureView.swift
//  lms
//
//  Created by Diptayan Jash on 09/05/25.
//

import Foundation
import SwiftUI

struct BookChatFeatureView: View {
    @Binding var showErrorAlert: Bool
    @Binding var errorMessage: String
    let colorScheme: ColorScheme

    @State private var chatMessages: [ChatMessage] = []
    @State private var chatInput: String = ""
    @State private var isChatLoading = false
    @State private var showClearChatAlert = false
    // @State private var isScrolledToBottom = true // This state might not be strictly necessary if using ScrollViewReader correctly

    @FocusState private var inputFieldIsFocused: Bool
    @Namespace private var bottomID // Used to identify the bottom of the ScrollView

    var body: some View {
        VStack(spacing: 0) {
            chatMessagesArea
                .onTapGesture {
                    inputFieldIsFocused = false // Dismiss keyboard
                }
            chatInputArea
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !chatMessages.isEmpty {
                    Button(action: {
                        inputFieldIsFocused = false
                        showClearChatAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.accent(for: colorScheme))
                    }
                }
            }
        }
        .alert("Clear Conversation", isPresented: $showClearChatAlert) {
            Button("Clear", role: .destructive) {
                withAnimation(.easeOut(duration: 0.3)) {
                    chatMessages.removeAll()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all messages in this conversation.")
        }
    }

    // MARK: - Chat UI Components

    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if chatMessages.isEmpty {
                        chatEmptyStateView
                            .padding(.top, 20)
                    } else {
                        ForEach(chatMessages) { message in
                            chatBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity), // Smoother insertion
                                    removal: .opacity
                                ))
                        }

                        if isChatLoading {
                            loadingIndicator
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, inputFieldIsFocused ? 10 : (chatMessages.isEmpty ? 0 : 10))
            }
//            .onChange(of: chatMessages.count) { _ in
//                scrollToBottom(proxy: proxy, animated: true)
//            }
//            .onChange(of: isChatLoading) { isLoading in
//                if isLoading {
//                    scrollToBottom(proxy: proxy, animated: true)
//                }
//            }
//            .onAppear {
//                if !chatMessages.isEmpty {
//                    scrollToBottom(proxy: proxy, animated: false)
//                }
//            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if animated {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accent(for: colorScheme)))
                .scaleEffect(0.8)
                .padding(.vertical, 10)
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9))) // Add scale to transition
    }

    private var chatEmptyStateView: some View {
        VStack(spacing: 24) {
//            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accent(for: colorScheme).opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.accent(for: colorScheme).opacity(0.8))
            }
            .padding(.bottom, 5)

            Text("Start a Conversation")
                .font(.title2.weight(.bold)) // Applied weight directly
                .foregroundColor(Color.text(for: colorScheme))

            Text("Ask Folio about books, authors, genres, or get recommendations!")
                .font(.callout)
                .foregroundColor(Color.secondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)

            Text("Try asking:")
                .font(.headline)
                .foregroundColor(Color.text(for: colorScheme))
                .padding(.top, 10)

            VStack(alignment: .center, spacing: 12) { // Ensure chips are centered if they wrap
                HStack(spacing: 10) {
                    exampleChip("Suggest a mystery novel")
                }
                HStack(spacing: 10) {
                    exampleChip("Books similar to Harry Potter")
                }
            }
            .padding(.horizontal) // Padding for the chip container

            Spacer()
//            Spacer()
        }
        .padding(.horizontal) // Outer padding for the empty state
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it tries to fill available space
    }

    private var chatInputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask about a book or author...", text: $chatInput)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                .background(
                    Capsule()
                        .fill(Color.primary(for: colorScheme).opacity(0.3))
                        .shadow(color: Color.black.opacity(colorScheme == .light ? 0.06 : 0.12),
                                radius: inputFieldIsFocused ? 5 : 3,
                                x: 0,
                                y: inputFieldIsFocused ? 2 : 1)
                )
                .overlay(
                    Capsule().stroke(inputFieldIsFocused ? Color.accent(for: colorScheme) : Color.accent(for: colorScheme).opacity(0.7), lineWidth: 1)
                )
                .focused($inputFieldIsFocused)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill") // Using filled icon for better tap target
                    .font(.system(size: 32)) // Slightly larger send icon
                    .foregroundColor(
                        chatInput.isEmpty || isChatLoading
                            ? Color.gray.opacity(0.6) // More distinct disabled state
                            : Color.primary(for: colorScheme)
                    )
            }
            .disabled(chatInput.isEmpty || isChatLoading)
            .scaleEffect(chatInput.isEmpty || isChatLoading ? 0.9 : 1.0) // Subtle scale effect
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: chatInput.isEmpty || isChatLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func exampleChip(_ text: String) -> some View {
        Button(action: {
            chatInput = text
            sendMessage()
        }) {
            Text(text)
                .font(.caption.weight(.medium)) // Slightly smaller font for chips
                .padding(.vertical)
                .padding(.horizontal)
                .background(
                    Capsule()
                        .fill(Color.accent(for: colorScheme).opacity(0.3)) // Softer background
                )
                .overlay(Capsule().stroke(Color.accent(for: colorScheme).opacity(0.2), lineWidth: 0.5)) // Subtle border
                .foregroundColor(Color.primary(for: colorScheme))
                .lineLimit(4) // Ensure chips stay on one line
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func chatBubble(message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle().fill(Color.primary(for: colorScheme).opacity(0.15)).frame(width: 32, height: 32) // Slightly smaller
                    Image(systemName: "apple.intelligence").font(.system(size: 15, weight: .regular)) // Adjusted icon
                        .foregroundColor(Color.accent(for: colorScheme))
                }
                .padding(.bottom, 10)

            } else {
                Spacer(minLength: UIScreen.main.bounds.width * 0.20)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 5) {
                // MARK: - Rich Text Display

                Text(LocalizedStringKey(message.content)) // << --- THIS IS THE KEY FOR MARKDOWN
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.isUser ?
                                Color.accent(for: colorScheme) :
                                Color.primary(for: colorScheme).opacity(0.35))
                            .shadow(color: Color.black.opacity(message.isUser ? 0.08 : 0.04),
                                    radius: 3, x: 1, y: 2)
                    )
                    .foregroundColor(Color.text(for: colorScheme))
                    .textSelection(.enabled) // Allow users to select/copy text
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)

                Text(formattedTime(message.timestamp))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Color.secondary(for: colorScheme).opacity(0.7))
                    .padding(.horizontal, 8) // Padding for timestamp
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: message.isUser ? .trailing : .leading) // Slightly narrower max width

            if message.isUser {
                // User avatar (optional, can be enabled if desired)
                ZStack {
                    Circle().fill(Color.secondary(for: colorScheme).opacity(0.2)).frame(width: 32, height: 32)
                    Image(systemName: "person.fill").font(.system(size: 15)).foregroundColor(Color.secondary(for: colorScheme))
                }
                .padding(.bottom, 10)
            } else {
                Spacer(minLength: UIScreen.main.bounds.width * 0.10) // Increased spacer for AI messages
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Chat Actions & Helpers

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func sendMessage() {
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        let userMessage = ChatMessage.userMessage(trimmedInput)
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) { // More dynamic spring
            chatMessages.append(userMessage)
        }

        let userQuery = trimmedInput
        chatInput = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { inputFieldIsFocused = false } // Animate focus out
        inputFieldIsFocused = false
        isChatLoading = true

        Task {
            try? await Task.sleep(for: .milliseconds(300)) // Use modern sleep

            do {
                let response = try await FolioService.shared.processBookInquiry(query: userQuery)
                await MainActor.run {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                        chatMessages.append(.aiMessage(response))
                    }
                    isChatLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessageText = "I'm sorry, there was an issue processing your request. Please try again. (\(error.localizedDescription.prefix(50))...)"
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                        chatMessages.append(.aiMessage(errorMessageText))
                    }
                    isChatLoading = false
                    // self.errorMessage = error.localizedDescription // Update shared error state
                    // self.showErrorAlert = true
                }
            }
        }
    }
}
