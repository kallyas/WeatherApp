import Foundation

/// Service for tracking analytics events throughout the app
class AnalyticsService {
    
    // MARK: - Properties
    
    private let isEnabled: Bool
    private let isDebugLoggingEnabled: Bool
    
    // In a real app, you would initialize SDK clients here
    // private let firebaseAnalytics: FirebaseAnalytics
    // private let mixpanelClient: MixpanelInstance
    
    // MARK: - Initialization
    
    init(isEnabled: Bool = true, isDebugLoggingEnabled: Bool = false) {
        self.isEnabled = isEnabled
        self.isDebugLoggingEnabled = isDebugLoggingEnabled
        
        // Initialize analytics SDKs here
        setupAnalytics()
    }
    
    // MARK: - Public Methods
    
    /// Log an event with optional parameters
    func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        // Log to console in debug mode
        if isDebugLoggingEnabled {
            print("📊 Analytics: \(eventName), params: \(parameters ?? [:])")
        }
        
        // In a real app, you would send to your analytics services
        // Firebase Analytics example:
        // Analytics.logEvent(eventName, parameters: parameters)
        
        // Mixpanel example:
        // Mixpanel.mainInstance().track(event: eventName, properties: parameters)
    }
    
    /// Log a screen view
    func logScreen(_ screenName: String) {
        guard isEnabled else { return }
        
        if isDebugLoggingEnabled {
            print("📊 Screen View: \(screenName)")
        }
        
        // Firebase screen tracking example:
        // Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        //     AnalyticsParameterScreenName: screenName,
        //     AnalyticsParameterScreenClass: screenName
        // ])
    }
    
    /// Log an error with context information
    func logError(_ error: Error, context: String) {
        guard isEnabled else { return }
        
        if isDebugLoggingEnabled {
            print("❌ Analytics Error: \(error.localizedDescription) in \(context)")
        }
        
        // In a real app, you would log to error tracking services
        // Crashlytics example:
        // Crashlytics.crashlytics().record(error: error)
        
        // Also track as an event
        logEvent("error_occurred", parameters: [
            "error_description": error.localizedDescription,
            "error_context": context,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ])
    }
    
    /// Log user properties
    func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled else { return }
        
        if isDebugLoggingEnabled {
            print("👤 User Property: \(name) = \(value ?? "nil")")
        }
        
        // Firebase example:
        // Analytics.setUserProperty(value, forName: name)
    }
    
    /// Log user ID
    func setUserID(_ userID: String?) {
        guard isEnabled else { return }
        
        if isDebugLoggingEnabled {
            if let userID = userID {
                print("👤 User ID: \(userID)")
            } else {
                print("👤 User ID cleared")
            }
        }
        
        // Firebase example:
        // Analytics.setUserID(userID)
    }
    
    // MARK: - Private Methods
    
    private func setupAnalytics() {
        if isDebugLoggingEnabled {
            print("📊 Analytics initialized. Enabled: \(isEnabled)")
        }
        
        // Configure analytics SDKs here
        // Firebase example:
        // FirebaseApp.configure()
    }
}

// MARK: - Analytics Event Constants

extension AnalyticsService {
    enum EventName {
        // App lifecycle events
        static let appOpen = "app_open"
        static let appBackground = "app_background"
        static let appForeground = "app_foreground"
        
        // Weather events
        static let weatherFetch = "weather_fetch"
        static let weatherRefresh = "weather_refresh"
        static let weatherFetchError = "weather_fetch_error"
        
        // Search events
        static let citySearch = "city_search"
        static let citySelected = "city_selected"
        
        // Settings events
        static let settingsChanged = "settings_changed"
        static let themeChanged = "theme_changed"
        static let unitsChanged = "units_changed"
        
        // Location events
        static let locationPermissionRequested = "location_permission_requested"
        static let locationPermissionGranted = "location_permission_granted"
        static let locationPermissionDenied = "location_permission_denied"
        static let locationUsed = "location_used"
        
        // Feature usage
        static let favoriteAdded = "favorite_added"
        static let favoriteRemoved = "favorite_removed"
        static let shareWeather = "share_weather"
    }
    
    enum UserProperty {
        static let theme = "theme"
        static let temperatureUnit = "temperature_unit"
        static let notificationsEnabled = "notifications_enabled"
        static let refreshFrequency = "refresh_frequency"
    }
    
    enum ScreenName {
        static let weather = "weather_screen"
        static let search = "search_screen"
        static let settings = "settings_screen"
        static let weatherMap = "weather_map_screen"
        static let savedLocations = "saved_locations_screen"
    }
}