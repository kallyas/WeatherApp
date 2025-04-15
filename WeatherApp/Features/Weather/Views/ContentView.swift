import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherViewModel: WeatherViewModel
    @AppStorage("selectedTheme") private var isDarkMode = false
    
    init() {
        let container = AppContainer()
        _weatherViewModel = StateObject(wrappedValue: WeatherViewModel(
            fetchWeatherUseCase: container.fetchWeatherUseCase,
            searchCityUseCase: container.searchCityUseCase
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            }
                        }
                    } else if weatherViewModel.currentWeather != nil {
                        WeatherDashboardView(
                            viewModel: weatherViewModel,
                            isDarkMode: $isDarkMode
                        )
                    } else {
                        WelcomeView {
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
                            if let location = locationManager.location {
                                weatherViewModel.fetchWeather(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                            } else {
                                locationManager.requestLocation()
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                        }
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                weatherViewModel.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}
