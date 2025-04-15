import Foundation
import Combine
import CoreLocation
import SwiftUI

class WeatherViewModel: ObservableObject {
    // Dependencies
    private let fetchWeatherUseCase: FetchWeatherUseCaseProtocol
    private let searchCityUseCase: SearchCityUseCaseProtocol
    
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
    
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    
    init(fetchWeatherUseCase: FetchWeatherUseCaseProtocol, searchCityUseCase: SearchCityUseCaseProtocol) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.searchCityUseCase = searchCityUseCase
        
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
    }
    
    func fetchWeather(for city: City) {
        selectedCity = city
        fetchWeather(latitude: city.coordinates.latitude, longitude: city.coordinates.longitude)
    }
    
    func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        fetchWeatherUseCase.execute(latitude: latitude, longitude: longitude)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                self?.currentWeather = response.current
                self?.hourlyForecast = Array(response.hourly.prefix(24))
                self?.dailyForecast = response.daily
                self?.timezone = response.timezone
            })
            .store(in: &cancellables)
    }
    
    func searchCity(query: String) {
        searchCityUseCase.execute(query: query) { [weak self] cities in
            self?.searchResults = cities
        }
    }
    
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
}
