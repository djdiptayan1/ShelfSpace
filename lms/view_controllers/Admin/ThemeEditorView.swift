//
//  ThemeEditorView.swift
//  lms
//
//  Created by dark on 13/05/25.
//

import SwiftUI

struct ThemeEditorView: View {
    // Observe the shared ThemeManager
    @ObservedObject var themeManager = ThemeManager.shared

    // Local state for editing. Initialize with current theme.
    @State private var editableTheme: ThemeData

    // State for color pickers (SwiftUI Color, not hex string)
    @State private var darkTextColor: Color
    @State private var lightTextColor: Color
    @State private var darkBackground1Color: Color
    @State private var lightBackground1Color: Color
    @State private var darkTabbarBackgroundColor: Color
    @State private var lightTabbarBackgroundColor: Color
    @State private var darkPrimaryColor: Color
    @State private var lightPrimaryColor: Color
    @State private var darkSecondaryColor: Color
    @State private var lightSecondaryColor: Color
    @State private var darkAccentColor: Color
    @State private var lightAccentColor: Color

    @State private var showSaveConfirmation = false
    @State private var isFetching = false

    // Initialize local state from the ThemeManager's current theme
    init() {
        let current = ThemeManager.shared.currentTheme
        _editableTheme = State(initialValue: current)

        _darkTextColor = State(initialValue: Color(hex: current.darkText))
        _lightTextColor = State(initialValue: Color(hex: current.lightText))
        _darkBackground1Color = State(initialValue: Color(hex: current.darkBackground1))
        _lightBackground1Color = State(initialValue: Color(hex: current.lightBackground1))
        _darkTabbarBackgroundColor = State(initialValue: Color(hex: current.darkBackground))
        _lightTabbarBackgroundColor = State(initialValue: Color(hex: current.lightBackground))
        _darkPrimaryColor = State(initialValue: Color(hex: current.darkPrimary))
        _lightPrimaryColor = State(initialValue: Color(hex: current.lightPrimary))
        _darkSecondaryColor = State(initialValue: Color(hex: current.darkSecondary))
        _lightSecondaryColor = State(initialValue: Color(hex: current.lightSecondary))
        _darkAccentColor = State(initialValue: Color(hex: current.darkAccent))
        _lightAccentColor = State(initialValue: Color(hex: current.lightAccent))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dark Mode Colors")) {
                    colorEditRow(label: "Text", hexString: $editableTheme.darkText, colorSelection: $darkTextColor)
                    colorEditRow(label: "Primary Background", hexString: $editableTheme.darkBackground1, colorSelection: $darkBackground1Color)
                    colorEditRow(label: "Tabbar Background", hexString: $editableTheme.darkBackground, colorSelection: $darkTabbarBackgroundColor)
                    colorEditRow(label: "Primary", hexString: $editableTheme.darkPrimary, colorSelection: $darkPrimaryColor)
                    colorEditRow(label: "Secondary", hexString: $editableTheme.darkSecondary, colorSelection: $darkSecondaryColor)
                    colorEditRow(label: "Accent", hexString: $editableTheme.darkAccent, colorSelection: $darkAccentColor)
                }

                Section(header: Text("Light Mode Colors")) {
                    colorEditRow(label: "Text", hexString: $editableTheme.lightText, colorSelection: $lightTextColor)
                    colorEditRow(label: "Primary Background", hexString: $editableTheme.lightBackground1, colorSelection: $lightBackground1Color)
                    colorEditRow(label: "Tabbar Background", hexString: $editableTheme.lightBackground, colorSelection: $lightTabbarBackgroundColor)
                    colorEditRow(label: "Primary", hexString: $editableTheme.lightPrimary, colorSelection: $lightPrimaryColor)
                    colorEditRow(label: "Secondary", hexString: $editableTheme.lightSecondary, colorSelection: $lightSecondaryColor)
                    colorEditRow(label: "Accent", hexString: $editableTheme.lightAccent, colorSelection: $lightAccentColor)
                }

                Section {
                    Button("Save Theme") {
                        saveTheme()
                    }
                    .disabled(!hasChanges) // Disable if no changes

                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .foregroundColor(.orange)

                    Button(action: {
                        fetchFromServer()
                    }) {
                        HStack {
                            Text("Fetch from Server")
                            if isFetching {
                                Spacer()
                                ProgressView().scaleEffect(0.7)
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(isFetching)
                }
            }
            .navigationTitle("Theme Editor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasChanges {
                        Button("Discard") {
                            discardChanges()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Theme Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) {}
            }
            // Update local Color state when hex changes (e.g., from text field edit or reset)
            .onChange(of: editableTheme) { newThemeData in
                 updateLocalColorStates(from: newThemeData)
            }
        }
        .navigationViewStyle(.stack) // Use stack style for better form presentation on iPad too
    }

    // Helper view for each color editor row
    @ViewBuilder
    private func colorEditRow(label: String, hexString: Binding<String>, colorSelection: Binding<Color>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            HStack {
                // Color Picker updates the SwiftUI Color
                ColorPicker("", selection: colorSelection, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 50)
                    // When ColorPicker changes, update the hex string
                    .onChange(of: colorSelection.wrappedValue) { newPickerColor in
                        hexString.wrappedValue = newPickerColor.toHex() ?? hexString.wrappedValue
                    }

                // Text Field for direct hex input (updates the hex string)
                TextField("Hex (e.g., #RRGGBB)", text: hexString)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    // When hex string changes from TextField, update the SwiftUI Color
                    .onChange(of: hexString.wrappedValue) { newHex in
                        let validHex = validateAndFormatHex(newHex)
                        if validHex != newHex { // Auto-correct format
                            hexString.wrappedValue = validHex
                        }
                        colorSelection.wrappedValue = Color(hex: validHex)
                    }
            }
        }
    }

    // Check if there are unsaved changes
    private var hasChanges: Bool {
        return editableTheme != themeManager.currentTheme
    }

    // MARK: - Actions

    private func saveTheme() {
        // Here, you'd typically also send the `editableTheme` to your server
        // to persist it on the backend if this is an admin feature.
        // For client-side only demo, we just update the ThemeManager.

        print("Saving theme to ThemeManager and local storage.")
        themeManager.currentTheme = editableTheme // This will trigger @Published update
        // ThemeManager should internally call its saveToStorage method
        // No, we need to explicitly call a method on ThemeManager to save
        themeManager.updateAndSaveTheme(editableTheme)

        showSaveConfirmation = true
    }

    private func resetToDefaults() {
        editableTheme = .defaultTheme
        // No need to call saveTheme() yet, user must explicitly save defaults
    }

    private func discardChanges() {
        editableTheme = themeManager.currentTheme // Revert to manager's current
    }

    private func fetchFromServer() {
//        isFetching = true
//        themeManager.fetchThemeFromServer { [weak themeManager] success in
//            isFetching = false
//            if success, let fetchedTheme = themeManager?.currentTheme {
//                // Update editableTheme when fetch is successful
//                editableTheme = fetchedTheme
//            }
//        }
    }

    // Helper to update local @State Color vars from ThemeData
    private func updateLocalColorStates(from themeData: ThemeData) {
        darkTextColor = Color(hex: themeData.darkText)
        lightTextColor = Color(hex: themeData.lightText)
        darkBackground1Color = Color(hex: themeData.darkBackground1)
        lightBackground1Color = Color(hex: themeData.lightBackground1)
        darkTabbarBackgroundColor = Color(hex: themeData.darkBackground)
        lightTabbarBackgroundColor = Color(hex: themeData.lightBackground)
        darkPrimaryColor = Color(hex: themeData.darkPrimary)
        lightPrimaryColor = Color(hex: themeData.lightPrimary)
        darkSecondaryColor = Color(hex: themeData.darkSecondary)
        lightSecondaryColor = Color(hex: themeData.lightSecondary)
        darkAccentColor = Color(hex: themeData.darkAccent)
        lightAccentColor = Color(hex: themeData.lightAccent)
    }
    
    // Helper to validate and ensure hex string has '#'
    private func validateAndFormatHex(_ hex: String) -> String {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !cleaned.hasPrefix("#") {
            cleaned = "#" + cleaned
        }
        // Basic validation for length and characters (can be more robust)
        let validChars = CharacterSet(charactersIn: "#0123456789ABCDEF")
        if cleaned.rangeOfCharacter(from: validChars.inverted) == nil && (cleaned.count == 7 || cleaned.count == 9 || cleaned.count == 4) {
            return cleaned
        }
        return hex // Return original if invalid to avoid breaking user input mid-type
    }
}

// MARK: - Add toHex() utility to Color
extension Color {
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

// MARK: - Modify ThemeManager


// MARK: - Preview
struct ThemeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeEditorView()
            .environmentObject(ThemeManager.shared) // Provide for preview
    }
}
