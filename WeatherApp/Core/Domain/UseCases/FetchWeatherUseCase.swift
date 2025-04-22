import Foundation
import Combine

protocol FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
}

class FetchWeatherUseCase: FetchWeatherUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    private let analyticsService: AnalyticsService?
    
    init(weatherRepository: WeatherRepositoryProtocol, analyticsService: AnalyticsService? = nil) {
        self.weatherRepository = weatherRepository
        self.analyticsService = analyticsService
    }
    
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        // Log the request for analytics
        analyticsService?.logEvent("fetch_weather", parameters: [
            "latitude": latitude,
            "longitude": longitude
        ])
        
        // Start a timer to measure response time
        let requestStartTime = Date()
        
        return weatherRepository.fetchWeather(latitude: latitude, longitude: longitude)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Calculate and log the response time
                let responseTime = Date().timeIntervalSince(requestStartTime)
                self?.analyticsService?.logEvent("weather_fetch_success", parameters: [
                    "response_time": responseTime,
                    "latitude": latitude,
                    "longitude": longitude
                ])
            }, receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    // Log error for analytics
                    self?.analyticsService?.logError(error, context: "fetch_weather")
                }
            })
            .eraseToAnyPublisher()
    }
}
