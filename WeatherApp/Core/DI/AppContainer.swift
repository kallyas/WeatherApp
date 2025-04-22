import Foundation

class AppContainer {
    // Use the app configuration instead of hardcoded values
    private let apiKey = AppConfiguration.apiKey
    
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
