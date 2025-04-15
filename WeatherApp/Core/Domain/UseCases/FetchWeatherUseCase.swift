import Foundation
import Combine

protocol FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
}

class FetchWeatherUseCase: FetchWeatherUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    
    init(weatherRepository: WeatherRepositoryProtocol) {
        self.weatherRepository = weatherRepository
    }
    
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        return weatherRepository.fetchWeather(latitude: latitude, longitude: longitude)
    }
}
