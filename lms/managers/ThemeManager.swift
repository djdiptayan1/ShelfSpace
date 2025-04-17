import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    private var appearanceObserver: NSObjectProtocol?
    
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
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
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
