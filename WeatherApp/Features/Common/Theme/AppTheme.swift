//
//  AppTheme.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//


import SwiftUI

// Theme options for the app
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// Manages theme settings
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var accentColor: Color {
        didSet {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(accentColor), requiringSecureCoding: false) {
                UserDefaults.standard.set(colorData, forKey: "accentColor")
            }
        }
    }
    
    init() {
        // Load theme from UserDefaults
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
        self.selectedTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        // Load accent color from UserDefaults, default to blue
        if let colorData = UserDefaults.standard.data(forKey: "accentColor"),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            self.accentColor = Color(color)
        } else {
            self.accentColor = .blue
        }
    }
    
    var isDarkMode: Bool {
        switch selectedTheme {
        case .dark: return true
        case .light: return false
        case .system: 
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// Extension for color helpers
extension Color {
    static var customAccent: Color {
        Color("AccentColor")
    }
    
    // Readable text color based on background brightness
    func readableText() -> Color {
        // Get the RGB components of the background color
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate luminance using the formula for human perceived brightness
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        // If the background is light, return dark text, and vice versa
        return luminance > 0.5 ? .black : .white
    }
}