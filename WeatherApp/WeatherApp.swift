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
            // Weather tab
            NavigationView {
                ContentView(
                    weatherViewModel: appContainer.makeWeatherViewModel()
                )
            }
            .tabItem {
                Label("Weather", systemImage: "cloud.sun.fill")
            }
            .tag(0)
            
            // Radar tab
            NavigationView {
                WeatherMapView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(1)
            
            // Cities tab
            NavigationView {
                SavedLocationsView(
                    locationsUseCase: appContainer.manageLocationsUseCase,
                    weatherViewModel: appContainer.makeWeatherViewModel()
                )
            }
            .tabItem {
                Label("Cities", systemImage: "list.bullet")
            }
            .tag(2)
            
            // Settings tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .accentColor(themeManager.accentColor)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

struct WeatherMapView: View {
    @State private var showingMapOptions = false
    
    var body: some View {
        ZStack {
            // Replace this with a MapKit integration in a real app
            Color(.systemGroupedBackground)
                .overlay(
                    VStack {
                        Image(systemName: "map.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .opacity(0.5)
                        
                        Text("Weather Map")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        Text("Weather radar would be displayed here")
                            .foregroundColor(.secondary)
                    }
                )
            
            // Map options button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingMapOptions = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                            .background(Circle().fill(Color(.systemBackground)))
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Weather Map")
        .actionSheet(isPresented: $showingMapOptions) {
            ActionSheet(
                title: Text("Map Options"),
                buttons: [
                    .default(Text("Temperature")) { },
                    .default(Text("Precipitation")) { },
                    .default(Text("Wind")) { },
                    .default(Text("Clouds")) { },
                    .default(Text("Pressure")) { },
                    .cancel()
                ]
            )
        }
    }
}

struct SavedLocationsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let locationsUseCase: ManageLocationsUseCaseProtocol
    let weatherViewModel: WeatherViewModel
    
    @State private var showingAddSheet = false
    @State private var recentLocations: [SavedLocation] = []
    @State private var favoriteLocations: [SavedLocation] = []
    
    var body: some View {
        List {
            // Favorite locations section
            Section(header: Text("Favorites")) {
                if favoriteLocations.isEmpty {
                    HStack {
                        Text("No favorite locations")
                            .foregroundColor(.secondary)
                            .italic()
                        Spacer()
                    }
                } else {
                    ForEach(favoriteLocations, id: \.id) { location in
                        Button(action: {
                            selectLocation(location)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(location.name)
                                        .font(.headline)
                                    Text(location.country)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        deleteFavorite(at: indexSet)
                    }
                }
            }
            
            // Recent locations section
            Section(header: Text("Recent")) {
                if recentLocations.isEmpty {
                    HStack {
                        Text("No recent locations")
                            .foregroundColor(.secondary)
                            .italic()
                        Spacer()
                    }
                } else {
                    ForEach(recentLocations, id: \.id) { location in
                        Button(action: {
                            selectLocation(location)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(location.name)
                                        .font(.headline)
                                    Text(location.country)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    toggleFavorite(location)
                                }) {
                                    Image(systemName: isFavorite(location) ? "star.fill" : "star")
                                        .foregroundColor(themeManager.accentColor)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
                
                if !recentLocations.isEmpty {
                    Button(action: {
                        locationsUseCase.clearRecentLocations()
                        loadLocations()
                    }) {
                        Text("Clear Recent")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Saved Locations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            SearchView(weatherViewModel: weatherViewModel)
        }
        .onAppear {
            loadLocations()
        }
    }
    
    private func loadLocations() {
        favoriteLocations = locationsUseCase.getFavoriteLocations()
        recentLocations = locationsUseCase.getRecentLocations()
    }
    
    private func selectLocation(_ location: SavedLocation) {
        let city = City(
            name: location.name,
            country: location.country,
            coordinates: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
        )
        weatherViewModel.fetchWeather(for: city)
    }
    
    private func isFavorite(_ location: SavedLocation) -> Bool {
        return favoriteLocations.contains(where: { $0.id == location.id })
    }
    
    private func toggleFavorite(_ location: SavedLocation) {
        if isFavorite(location) {
            locationsUseCase.removeFromFavorites(location.id)
        } else {
            locationsUseCase.addToFavorites(location)
        }
        loadLocations()
    }
    
    private func deleteFavorite(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let location = favoriteLocations[index]
            locationsUseCase.removeFromFavorites(location.id)
        }
        loadLocations()
    }
}
