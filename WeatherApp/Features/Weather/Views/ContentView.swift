import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherViewModel: WeatherViewModel
    @AppStorage("selectedTheme") private var isDarkMode = false
    
    // Track if we've already loaded initial data
    @State private var initialDataLoaded = false
    
    init() {
        // Use the proper configuration for API keys
        let container = AppContainer()
        _weatherViewModel = StateObject(wrappedValue: WeatherViewModel(
            fetchWeatherUseCase: container.fetchWeatherUseCase,
            searchCityUseCase: container.searchCityUseCase
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background based on current weather or default
                BackgroundView(
                    backgroundType: weatherViewModel.currentWeather?.weather.first.map {
                        weatherViewModel.getWeatherBackground(from: $0.icon)
                    } ?? .clear,
                    isDarkMode: isDarkMode
                )
                
                VStack {
                    if weatherViewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = weatherViewModel.errorMessage {
                        ErrorView(message: errorMessage) {
                            // Retry action
                            if let city = weatherViewModel.selectedCity {
                                weatherViewModel.fetchWeather(for: city)
                            } else if let location = locationManager.location {
                                weatherViewModel.fetchWeather(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                            } else {
                                // Reset authorization request flag before retrying
                                locationManager.resetAuthorizationRequest()
                                locationManager.requestLocation()
                            }
                        }
                    } else if weatherViewModel.currentWeather != nil {
                        WeatherDashboardView(
                            viewModel: weatherViewModel,
                            isDarkMode: $isDarkMode
                        )
                    } else {
                        // This is the initial state - show welcome view
                        WelcomeView {
                            // Reset the flag before requesting location again
                            locationManager.resetAuthorizationRequest()
                            locationManager.requestLocation()
                        }
                    }
                }
                .navigationTitle("Weather")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isDarkMode.toggle()
                        }) {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(isDarkMode ? .yellow : .indigo)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Reset the flag before requesting location
                            locationManager.resetAuthorizationRequest()
                            locationManager.requestLocation()
                        }) {
                            Image(systemName: "location.circle.fill")
                        }
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                // Only run this once when the view appears
                if !initialDataLoaded {
                    initialDataLoaded = true
                    
                    // Try to load the last viewed city first
                    if let lastCity = UserDefaults.standard.getLastViewedCity() {
                        print("Loading last viewed city: \(lastCity.name)")
                        weatherViewModel.fetchWeather(for: lastCity)
                    } else {
                        // If no last city, then request location
                        print("No last city found, requesting location")
                        locationManager.requestLocation()
                    }
                }
            }
            .alert(item: $locationManager.locationError) { error in
                Alert(
                    title: Text("Location Access Required"),
                    message: Text(error.description),
                    primaryButton: .default(Text("Settings")) {
                        locationManager.openAppSettings()
                    },
                    secondaryButton: .cancel {
                        // If user cancels and we have no weather data, show a search option
                        if weatherViewModel.currentWeather == nil {
                            weatherViewModel.errorMessage = "Please search for a city to see weather information."
                        }
                    }
                )
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                print("Location changed, fetching weather for new coordinates")
                weatherViewModel.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}
