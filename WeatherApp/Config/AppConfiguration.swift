import Foundation

enum AppConfiguration {
    // MARK: - API Keys
    
    #if DEBUG
    // For debug builds - prioritize environment variable, then Info.plist, then fallback
    static let apiKey: String = {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"], !envKey.isEmpty {
            print("Using API key from environment variable")
            return envKey
        }
        
        // Then check Info.plist
        if let infoKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String,
           !infoKey.isEmpty && !infoKey.contains("YOUR_") {
            print("Using API key from Info.plist")
            return infoKey
        }
        
        // Finally, use hardcoded fallback (for development only)
        print("Using hardcoded API key")
        return "5efdef10c152bb44862a64e738656f70" // Your API key from logs
    }()
    #else
    // For release builds - only use secure methods
    static let apiKey: String = {
        // First try environment variable (for CI/CD)
        if let envKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Then Info.plist (set by build settings)
        if let infoKey = Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String, !infoKey.isEmpty {
            return infoKey
        }
        
        // Fail gracefully - return empty but log error
        print("ERROR: No API key found for production build")
        return ""
    }()
    #endif
    
    // MARK: - API URLs
    
    // Updated to use 2.5 endpoint which works with the free tier
    static let baseURL = "https://api.openweathermap.org/data/2.5"
    static let geoURL = "https://api.openweathermap.org/geo/1.0"
    
    // MARK: - App Configuration
    
    static let defaultTempUnit = "metric" // metric or imperial
    static let cacheDuration: TimeInterval = 60 * 30 // 30 minutes
    
    // MARK: - Helper Methods
    
    static func isAPIKeyValid() -> Bool {
        // Basic validation - not empty and not a placeholder
        return !apiKey.isEmpty && !apiKey.contains("YOUR_")
    }
    
    static func logAPIStatus() {
        #if DEBUG
        if isAPIKeyValid() {
            print("API key configured: \(apiKey)")
        } else {
            print("WARNING: Invalid API key configuration")
        }
        #endif
    }
}
