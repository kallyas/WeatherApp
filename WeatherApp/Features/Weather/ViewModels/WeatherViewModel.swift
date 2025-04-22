import Foundation
import Combine
import CoreLocation
import SwiftUI

class WeatherViewModel: ObservableObject {
    // Dependencies
    private let fetchWeatherUseCase: FetchWeatherUseCaseProtocol
    private let searchCityUseCase: SearchCityUseCaseProtocol
    private let manageLocationsUseCase: ManageLocationsUseCaseProtocol
    private let locationService: LocationService
    
    // Published properties
    @Published var currentWeather: CurrentWeather?
    @Published var hourlyForecast: [HourlyForecast] = []
    @Published var dailyForecast: [DailyForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var timezone: String?
    @Published var selectedCity: City?
    @Published var searchResults: [City] = []
    @Published var searchText = ""
    @Published var lastUpdated: Date?
    @Published var isRefreshing = false
    
    // Refresh timer
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = 30 * 60 // Default 30 minutes
    
    private var cancellables = Set<AnyCancellable>()
    
    init(fetchWeatherUseCase: FetchWeatherUseCaseProtocol,
         searchCityUseCase: SearchCityUseCaseProtocol,
         manageLocationsUseCase: ManageLocationsUseCaseProtocol,
         locationService: LocationService) {
        
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.searchCityUseCase = searchCityUseCase
        self.manageLocationsUseCase = manageLocationsUseCase
        self.locationService = locationService
        
        // Setup search debounce
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self, !searchTerm.isEmpty, searchTerm.count >= 2 else {
                    self?.searchResults = []
                    return
                }
                self.searchCity(query: searchTerm)
            }
            .store(in: &cancellables)
        
        // Setup refresh timer observer
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateRefreshInterval()
            }
            .store(in: &cancellables)
        
        // Initial setup of refresh timer
        updateRefreshInterval()
    }
    
    deinit {
        stopRefreshTimer()
    }
    
    // MARK: - Public Methods
    
    func fetchWeather(for city: City) {
        selectedCity = city
        
        // Save to recent locations
        let savedLocation = SavedLocation(
            id: UUID().uuidString,
            name: city.name,
            country: city.country,
            latitude: city.coordinates.latitude,
            longitude: city.coordinates.longitude
        )
        manageLocationsUseCase.addToRecentLocations(savedLocation)
        
        // Save to UserDefaults for persistent storage
        UserDefaults.standard.saveLastViewedCity(
            cityName: city.name,
            latitude: city.coordinates.latitude,
            longitude: city.coordinates.longitude,
            country: city.country
        )
        
        fetchWeather(latitude: city.coordinates.latitude, longitude: city.coordinates.longitude)
    }
    
    func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        print("Fetching weather for lat: \(latitude), lon: \(longitude)")
        
        fetchWeatherUseCase.execute(latitude: latitude, longitude: longitude)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                self?.isRefreshing = false
                
                if case .failure(let error) = completion {
                    if let networkError = error as? NetworkError, networkError == NetworkError.noConnection {
                        self?.errorMessage = "No internet connection. Showing cached data if available."
                    } else {
                        self?.errorMessage = "Could not load weather data: \(error.localizedDescription)"
                    }
                    print("Weather fetch error: \(error)")
                }
            }, receiveValue: { [weak self] response in
                self?.currentWeather = response.current
                self?.hourlyForecast = Array(response.hourly.prefix(48))
                self?.dailyForecast = response.daily
                self?.timezone = response.timezone
                self?.lastUpdated = Date()
                
                // If we got weather data but don't have a selected city (came from location),
                // create a "Current Location" city
                if self?.selectedCity == nil {
                    self?.selectedCity = City(
                        name: "Current Location",
                        country: "",
                        coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    )
                }
                
                print("Successfully loaded weather data")
            })
            .store(in: &cancellables)
    }
    
    func refreshWeatherData() {
        isRefreshing = true
        
        if let city = selectedCity {
            fetchWeather(
                latitude: city.coordinates.latitude,
                longitude: city.coordinates.longitude
            )
        } else {
            locationService.requestLocation { [weak self] result in
                switch result {
                case .success(let location):
                    self?.fetchWeather(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                case .failure(let error):
                    self?.isRefreshing = false
                    self?.errorMessage = "Could not update location: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func searchCity(query: String) {
        print("Searching for city: \(query)")
        
        searchCityUseCase.execute(query: query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cities):
                    self?.searchResults = cities
                    print("Found \(cities.count) cities for query: \(query)")
                case .failure(let error):
                    self?.searchResults = []
                    print("Error searching cities: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchCurrentLocationWeather() {
        locationService.requestLocation { [weak self] result in
            switch result {
            case .success(let location):
                self?.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            case .failure(let error):
                self?.errorMessage = "Could not get location: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getWeatherIcon(from icon: String) -> String {
        switch icon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
    
    func getWeatherBackground(from icon: String) -> BackgroundType {
        let firstChar = icon.prefix(2)
        switch firstChar {
        case "01": return .clear
        case "02", "03", "04": return .cloudy
        case "09", "10": return .rainy
        case "11": return .stormy
        case "13": return .snowy
        case "50": return .foggy
        default: return .clear
        }
    }
    
    // MARK: - Private Methods
    
    private func updateRefreshInterval() {
        let minutes = UserDefaults.standard.integer(forKey: "refreshFrequency")
        refreshInterval = TimeInterval(minutes * 60)
        
        // Restart timer with new interval
        stopRefreshTimer()
        startRefreshTimer()
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refreshWeatherData()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
