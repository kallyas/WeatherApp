import Foundation

protocol SearchCityUseCaseProtocol {
    func execute(query: String, completion: @escaping ([City]) -> Void)
}

class SearchCityUseCase: SearchCityUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    
    init(weatherRepository: WeatherRepositoryProtocol) {
        self.weatherRepository = weatherRepository
    }
    
    func execute(query: String, completion: @escaping ([City]) -> Void) {
        weatherRepository.searchCity(query: query, completion: completion)
    }
}
