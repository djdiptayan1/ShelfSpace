import SwiftUI
import Combine
import UIKit

class ThemeManager: ObservableObject {
    static let shared = ThemeManager() // Singleton for easy access

    @Published var isDarkMode: Bool = false
    private var appearanceObserver: NSObjectProtocol?
    @Published var currentTheme: ThemeData = .defaultTheme
    private var cancellables = Set<AnyCancellable>()

    private let themeStorageKey = "appCurrentTheme"
    private let socketHandler = SocketHandler<ThemeData>()

    
    init() {
        // Initial check of system appearance
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        // Observe appearance changes
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAppearance()
        }
        loadThemeFromStorage()
        fetchTheme()
        handleSocket()
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    private func clearThemeFromStorage() {
        UserDefaults.standard.removeObject(forKey: themeStorageKey)
    }
    private func fetchTheme(){
        Task{
            if let theme = try await ThemeHandler.shared.getTheme(){
                self.currentTheme = theme
                self.saveThemeToStorage(theme)
            }
        }
    }
    private func handleSocket(){
        socketHandler.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [self] message in
                currentTheme = message.data
            }.store(in: &cancellables)
    }
    func updateAndSaveTheme(_ newTheme: ThemeData) {
            self.currentTheme = newTheme // This will publish changes
            self.saveThemeToStorage(newTheme) // Persist it
            Task{
                try await ThemeHandler.shared.updateTheme(newTheme)
            }
            print("Theme updated by editor and saved.")
    }
    private func loadThemeFromStorage() {
            if let savedThemeData = UserDefaults.standard.data(forKey: themeStorageKey) {
                do {
                    let decoder = JSONDecoder()
                    let loadedTheme = try decoder.decode(ThemeData.self, from: savedThemeData)
                    self.currentTheme = loadedTheme
                    print("Theme loaded from UserDefaults.")
                } catch {
                    print("Error decoding theme from UserDefaults: \(error). Using defaults.")
                    self.currentTheme = .defaultTheme
                }
            } else {
                print("No theme found in UserDefaults. Using defaults.")
                self.currentTheme = .defaultTheme
            }
        }

        private func saveThemeToStorage(_ theme: ThemeData) {
            do {
                let encoder = JSONEncoder()
                let themeData = try encoder.encode(theme)
                UserDefaults.standard.set(themeData, forKey: themeStorageKey)
                print("Theme saved to UserDefaults.")
            } catch {
                print("Error encoding theme for UserDefaults: \(error)")
            }
        }
    
    func updateAppearance() {
        DispatchQueue.main.async {
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    func update(with colorScheme: ColorScheme) {
        self.isDarkMode = colorScheme == .dark
    }
} 



struct ThemeData: Codable, Equatable { // Equatable to detect changes
    var darkText: String
    var lightText: String
    var darkBackground1: String
    var lightBackground1: String
    var darkBackground: String  // For Tabbar
    var lightBackground: String // For Tabbar
    var darkPrimary: String
    var lightPrimary: String
    var darkSecondary: String
    var lightSecondary: String
    var darkAccent: String
    var lightAccent: String

    // Provide default fallback values
    static let defaultTheme = ThemeData(
        darkText: ColorConstants.darkText, lightText: ColorConstants.lightText,
        darkBackground1: ColorConstants.darkBackground1, lightBackground1: ColorConstants.lightBackground1,
        darkBackground: ColorConstants.darkBackground, lightBackground: ColorConstants.lightBackground,
        darkPrimary: ColorConstants.darkPrimary, lightPrimary: ColorConstants.lightPrimary,
        darkSecondary: ColorConstants.darkSecondary, lightSecondary: ColorConstants.lightSecondary,
        darkAccent: ColorConstants.darkAccent, lightAccent: ColorConstants.lightAccent
    )
}
