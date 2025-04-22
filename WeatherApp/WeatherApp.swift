import SwiftUI
import CoreLocation

@main
struct WeatherApp: App {
    // Create the app container as a StateObject to keep it alive throughout app lifecycle
    @StateObject private var appContainer = AppContainer()
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // Configure app appearance at startup
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(appContainer)
                .onAppear {
                    // Request notification permissions on app start
                    if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                        requestNotificationPermission()
                    }
                }
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Apply customizations
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Register default settings if not already set
        registerDefaultSettings()
    }
    
    private func registerDefaultSettings() {
        let defaultSettings: [String: Any] = [
            "selectedTheme": "system",
            "useMetric": true,
            "hourFormat": "12h",
            "notificationsEnabled": false,
            "refreshFrequency": 30
        ]
        
        UserDefaults.standard.register(defaults: defaultSettings)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var appContainer: AppContainer
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Weather tab - Remove NavigationView wrapper
            ContentView(
                weatherViewModel: appContainer.makeWeatherViewModel()
            )
            .tabItem {
                Label("Weather", systemImage: "cloud.sun.fill")
            }
            .tag(0)
            
            // Radar tab - Remove NavigationView wrapper
            WeatherMapView()
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(1)
            
            // Cities tab - Remove NavigationView wrapper
            SavedLocationsView(
                locationsUseCase: appContainer.manageLocationsUseCase,
                weatherViewModel: appContainer.makeWeatherViewModel()
            )
            .tabItem {
                Label("Cities", systemImage: "list.bullet")
            }
            .tag(2)
            
            // Settings tab - Remove NavigationView wrapper
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .accentColor(themeManager.accentColor)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}
