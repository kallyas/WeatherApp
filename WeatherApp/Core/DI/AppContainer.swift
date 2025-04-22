import Foundation
import CoreLocation
import Combine // Add this import for ObservableObject

// Dependency Injection Container following the Service Locator pattern
class AppContainer: ObservableObject {
    // Core Services
    private(set) lazy var networkMonitor = NetworkMonitorService()
    private(set) lazy var analyticsService = AnalyticsService()
    private(set) lazy var locationService = LocationService()
    
    // API Services
    private(set) lazy var weatherAPIService: WeatherAPIServiceProtocol = {
        return WeatherAPIService(apiKey: AppConfiguration.apiKey)
    }()
    
    // Caching
    private(set) lazy var weatherCacheService: WeatherCacheServiceProtocol = {
        return WeatherCacheService(cacheDuration: AppConfiguration.cacheDuration)
    }()
    
    // MARK: - Repositories
    
    private(set) lazy var weatherRepository: WeatherRepositoryProtocol = {
        return WeatherRepository(
            weatherAPIService: weatherAPIService,
            cacheService: weatherCacheService,
            networkMonitor: networkMonitor
        )
    }()
    
    // MARK: - Use Cases
    
    private(set) lazy var fetchWeatherUseCase: FetchWeatherUseCaseProtocol = {
        return FetchWeatherUseCase(weatherRepository: weatherRepository)
    }()
    
    private(set) lazy var searchCityUseCase: SearchCityUseCaseProtocol = {
        return SearchCityUseCase(weatherRepository: weatherRepository)
    }()
    
    private(set) lazy var manageLocationsUseCase: ManageLocationsUseCaseProtocol = {
        return ManageLocationsUseCase()
    }()
    
    // MARK: - View Models
    
    func makeWeatherViewModel() -> WeatherViewModel {
        return WeatherViewModel(
            fetchWeatherUseCase: fetchWeatherUseCase,
            searchCityUseCase: searchCityUseCase,
            manageLocationsUseCase: manageLocationsUseCase,
            locationService: locationService
        )
    }
    
    // MARK: - Lifecycle
    
    init() {
        AppConfiguration.logAPIStatus()
        networkMonitor.startMonitoring()
    }
    
    deinit {
        networkMonitor.stopMonitoring()
    }
}
