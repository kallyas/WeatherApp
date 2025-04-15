import Foundation
import Combine

protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
    func searchCity(query: String, completion: @escaping ([City]) -> Void)
}

class WeatherRepository: WeatherRepositoryProtocol {
    private let weatherAPIService: WeatherAPIServiceProtocol
    
    init(weatherAPIService: WeatherAPIServiceProtocol) {
        self.weatherAPIService = weatherAPIService
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        return weatherAPIService.fetchWeather(latitude: latitude, longitude: longitude)
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        weatherAPIService.searchCity(query: query, completion: completion)
    }
}
