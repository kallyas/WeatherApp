import Foundation
import Combine
import CoreLocation

protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
    func searchCity(query: String, completion: @escaping (Result<[City], Error>) -> Void)
    func clearCache()
}

class WeatherRepository: WeatherRepositoryProtocol {
    private let weatherAPIService: WeatherAPIServiceProtocol
    private let cacheService: WeatherCacheServiceProtocol
    private let networkMonitor: NetworkMonitorServiceProtocol
    
    init(weatherAPIService: WeatherAPIServiceProtocol,
         cacheService: WeatherCacheServiceProtocol,
         networkMonitor: NetworkMonitorServiceProtocol) {
        self.weatherAPIService = weatherAPIService
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Check if network is available
        if !networkMonitor.isConnected {
            print("Network unavailable, trying cache...")
            
            // If no network, try to use cached data
            if let cachedWeather = cacheService.getCachedWeather(for: coordinates) {
                print("Using cached weather data")
                return Just(cachedWeather)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                // No cache, return network error
                print("No cached data available")
                return Fail(error: NetworkError.noConnection)
                    .eraseToAnyPublisher()
            }
        }
        
        // If network available, fetch fresh data
        return weatherAPIService.fetchWeather(latitude: latitude, longitude: longitude)
            .handleEvents(receiveOutput: { [weak self] weatherData in
                // Cache the successfully fetched data
                self?.cacheService.cacheWeather(weatherData, for: coordinates)
                print("Weather data cached")
            })
            .catch { [weak self] error -> AnyPublisher<WeatherResponse, Error> in
                guard let self = self else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                // On error, try to fall back to cache
                print("API error: \(error.localizedDescription), checking cache...")
                if let cachedWeather = self.cacheService.getCachedWeather(for: coordinates) {
                    print("Returning cached weather data after API error")
                    return Just(cachedWeather)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                // No cache available, propagate the original error
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping (Result<[City], Error>) -> Void) {
        // Check if network is available
        if !networkMonitor.isConnected {
            completion(.failure(NetworkError.noConnection))
            return
        }
        
        weatherAPIService.searchCity(query: query) { [weak self] cities in
            // Log the search for analytics
            self?.logCitySearch(query: query, results: cities.count)
            
            completion(.success(cities))
        }
    }
    
    func clearCache() {
        cacheService.clearCache()
        print("Weather cache cleared")
    }
    
    // MARK: - Private Helper Methods
    
    private func logCitySearch(query: String, results: Int) {
        // This would connect to analytics in a real app
        print("City search: '\(query)' found \(results) results")
    }
}

// MARK: - Error Types

import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case noConnection
    case serverError(Int)
    case invalidResponse
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available. Please check your connection and try again."
        case .serverError(let code):
            return "Server error with code: \(code). Please try again later."
        case .invalidResponse:
            return "Invalid response from the server. Please try again."
        case .invalidData:
            return "Could not process the data from the server. Please try again."
        }
    }
    
    // Implementation of Equatable protocol
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.invalidData, .invalidData):
            return true
        case (.serverError(let code1), .serverError(let code2)):
            return code1 == code2
        default:
            return false
        }
    }
}
