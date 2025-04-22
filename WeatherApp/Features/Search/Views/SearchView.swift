import SwiftUI
import CoreLocation

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNoResults = false
    @State private var showingFavorites = false
    @State private var showingRecents = true
    @State private var searchFocused = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    @AppStorage("favoriteLocations") private var favoriteLocationsData: Data = Data()
    
    var recentSearches: [SavedLocation] {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([SavedLocation].self, from: recentSearchesData) {
            return decoded
        }
        return []
    }
    
    var favoriteLocations: [SavedLocation] {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([SavedLocation].self, from: favoriteLocationsData) {
            return decoded
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for a city", text: $weatherViewModel.searchText)
                            .autocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .focused($isTextFieldFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isTextFieldFocused = true
                                }
                            }
                            .onChange(of: isTextFieldFocused) { isFocused in
                                searchFocused = isFocused
                            }
                        
                        if !weatherViewModel.searchText.isEmpty {
                            Button(action: {
                                weatherViewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                    
                    if !searchFocused && weatherViewModel.searchText.isEmpty {
                        // Section picker when not searching
                        Picker("Locations", selection: $showingFavorites) {
                            Text("Recent").tag(false)
                            Text("Favorites").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Search results or saved locations
                    if weatherViewModel.isLoading {
                        Spacer()
                        ProgressView("Searching...")
                        Spacer()
                    } else if !weatherViewModel.searchText.isEmpty {
                        // Search results
                        if weatherViewModel.searchResults.isEmpty && weatherViewModel.searchText.count >= 2 {
                            Spacer()
                            ContentUnavailableView(
                                "No Cities Found",
                                systemImage: "magnifyingglass",
                                description: Text("Try a different search term")
                            )
                            Spacer()
                        } else {
                            searchResultsList
                                .transition(.opacity)
                        }
                    } else if showingFavorites {
                        // Favorites list
                        if favoriteLocations.isEmpty {
                            Spacer()
                            ContentUnavailableView(
                                "No Favorites Yet",
                                systemImage: "star",
                                description: Text("Add favorite locations for quick access")
                            )
                            Spacer()
                        } else {
                            savedLocationsList(locations: favoriteLocations, isFavorite: true)
                                .transition(.opacity)
                        }
                    } else {
                        // Recent searches
                        if recentSearches.isEmpty {
                            Spacer()
                            ContentUnavailableView(
                                "No Recent Searches",
                                systemImage: "clock",
                                description: Text("Your search history will appear here")
                            )
                            Spacer()
                        } else {
                            savedLocationsList(locations: recentSearches, isFavorite: false)
                                .transition(.opacity)
                        }
                    }
                    
                    if weatherViewModel.searchText.isEmpty && !searchFocused {
                        // Current location button at bottom
                        Button(action: {
                            requestCurrentWeather()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Current Location")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(themeManager.accentColor)
                            .cornerRadius(12)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(weatherViewModel.searchResults) { city in
                Button(action: {
                    selectCity(city)
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(city.name)
                                .font(.headline)
                            Text(city.country)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            toggleFavorite(city)
                        }) {
                            Image(systemName: isFavorite(city) ? "star.fill" : "star")
                                .foregroundColor(themeManager.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func savedLocationsList(locations: [SavedLocation], isFavorite: Bool) -> some View {
        List {
            ForEach(locations, id: \.id) { savedLocation in
                Button(action: {
                    let city = City(
                        name: savedLocation.name,
                        country: savedLocation.country,
                        coordinates: CLLocationCoordinate2D(
                            latitude: savedLocation.latitude,
                            longitude: savedLocation.longitude
                        )
                    )
                    selectCity(city)
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(savedLocation.name)
                                .font(.headline)
                            Text(savedLocation.country)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if isFavorite {
                            Button(action: {
                                removeFavorite(savedLocation)
                            }) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(themeManager.accentColor)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
                            Button(action: {
                                toggleFavorite(savedLocation)
                            }) {
                                Image(systemName: isFavoriteById(savedLocation.id) ? "star.fill" : "star")
                                    .foregroundColor(themeManager.accentColor)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .onDelete { indexSet in
                deleteLocation(at: indexSet, from: isFavorite ? favoriteLocations : recentSearches, isFavorite: isFavorite)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func selectCity(_ city: City) {
        weatherViewModel.fetchWeather(for: city)
        addToRecentSearches(city)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func requestCurrentWeather() {
        let locationManager = LocationManager()
        locationManager.requestLocation()
    }
    
    private func addToRecentSearches(_ city: City) {
        let savedLocation = SavedLocation(
            id: UUID().uuidString,
            name: city.name,
            country: city.country,
            latitude: city.coordinates.latitude,
            longitude: city.coordinates.longitude
        )
        
        var recents = recentSearches
        // Remove if already exists to avoid duplicates
        recents.removeAll { $0.name == city.name && $0.country == city.country }
        // Add to beginning
        recents.insert(savedLocation, at: 0)
        // Limit to 10 recent searches
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        
        saveRecentSearches(recents)
    }
    
    private func saveRecentSearches(_ searches: [SavedLocation]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(searches) {
            recentSearchesData = encoded
        }
    }
    
    private func saveFavoriteLocations(_ favorites: [SavedLocation]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(favorites) {
            favoriteLocationsData = encoded
        }
    }
    
    private func isFavorite(_ city: City) -> Bool {
        return favoriteLocations.contains {
            $0.name == city.name && $0.country == city.country
        }
    }
    
    private func isFavoriteById(_ id: String) -> Bool {
        return favoriteLocations.contains { $0.id == id }
    }
    
    private func toggleFavorite(_ city: City) {
        if isFavorite(city) {
            var favorites = favoriteLocations
            favorites.removeAll { $0.name == city.name && $0.country == city.country }
            saveFavoriteLocations(favorites)
        } else {
            let savedLocation = SavedLocation(
                id: UUID().uuidString,
                name: city.name,
                country: city.country,
                latitude: city.coordinates.latitude,
                longitude: city.coordinates.longitude
            )
            var favorites = favoriteLocations
            favorites.append(savedLocation)
            saveFavoriteLocations(favorites)
        }
    }
    
    private func toggleFavorite(_ location: SavedLocation) {
        if isFavoriteById(location.id) {
            removeFavorite(location)
        } else {
            var favorites = favoriteLocations
            favorites.append(location)
            saveFavoriteLocations(favorites)
        }
    }
    
    private func removeFavorite(_ location: SavedLocation) {
        var favorites = favoriteLocations
        favorites.removeAll { $0.id == location.id }
        saveFavoriteLocations(favorites)
    }
    
    private func deleteLocation(at indexSet: IndexSet, from locations: [SavedLocation], isFavorite: Bool) {
        var updated = locations
        indexSet.forEach { updated.remove(at: $0) }
        
        if isFavorite {
            saveFavoriteLocations(updated)
        } else {
            saveRecentSearches(updated)
        }
    }
}

// Model for saved locations
struct SavedLocation: Codable, Identifiable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
}
