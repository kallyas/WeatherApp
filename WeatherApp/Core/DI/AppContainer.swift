import Foundation

class AppContainer {
    // API Key - Replace with your actual API key
    private let apiKey = "YOUR_OPENWEATHER_API_KEY"
    
    // Services
    lazy var weatherAPIService: WeatherAPIServiceProtocol = {
        return WeatherAPIService(apiKey: apiKey)
    }()
    
    // Repositories
    lazy var weatherRepository: WeatherRepositoryProtocol = {
        return WeatherRepository(weatherAPIService: weatherAPIService)
    }()
    
    // Use Cases
    lazy var fetchWeatherUseCase: FetchWeatherUseCaseProtocol = {
        return FetchWeatherUseCase(weatherRepository: weatherRepository)
    }()
    
    lazy var searchCityUseCase: SearchCityUseCaseProtocol = {
        return SearchCityUseCase(weatherRepository: weatherRepository)
    }()
}
