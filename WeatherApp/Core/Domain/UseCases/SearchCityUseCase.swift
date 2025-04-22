import Foundation

protocol SearchCityUseCaseProtocol {
    func execute(query: String, completion: @escaping (Result<[City], Error>) -> Void)
}

class SearchCityUseCase: SearchCityUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    private let analyticsService: AnalyticsService?
    
    init(weatherRepository: WeatherRepositoryProtocol, analyticsService: AnalyticsService? = nil) {
        self.weatherRepository = weatherRepository
        self.analyticsService = analyticsService
    }
    
    func execute(query: String, completion: @escaping (Result<[City], Error>) -> Void) {
        // Validate query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            completion(.success([]))
            return
        }
        
        // Log the search query for analytics
        analyticsService?.logEvent("city_search", parameters: [
            "query": trimmedQuery
        ])
        
        // Delegate to repository
        weatherRepository.searchCity(query: trimmedQuery) { [weak self] result in
            switch result {
            case .success(let cities):
                // Log search results
                self?.analyticsService?.logEvent("city_search_results", parameters: [
                    "query": trimmedQuery,
                    "result_count": cities.count
                ])
                
                completion(.success(cities))
                
            case .failure(let error):
                // Log error
                self?.analyticsService?.logError(error, context: "city_search")
                
                completion(.failure(error))
            }
        }
    }
}
