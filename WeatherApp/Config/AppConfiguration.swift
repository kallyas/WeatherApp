import Foundation

enum AppConfiguration {
    // MARK: - API Keys
    
    #if DEBUG
    static let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_OPENWEATHER_API_KEY"
    #else
    static let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_PRODUCTION_API_KEY"
    #endif
    
    // MARK: - API URLs
    
    static let baseURL = "https://api.openweathermap.org/data/3.0"
    static let geoURL = "https://api.openweathermap.org/geo/1.0"
    
    // MARK: - App Configuration
    
    static let defaultTempUnit = "metric" // metric or imperial
    static let cacheDuration: TimeInterval = 60 * 30 // 30 minutes
}
