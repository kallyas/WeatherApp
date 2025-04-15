import Foundation
import Combine
import CoreLocation

protocol WeatherAPIServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
    func searchCity(query: String, completion: @escaping ([City]) -> Void)
}

class WeatherAPIService: WeatherAPIServiceProtocol {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        guard let url = APIEndpoints.weatherURL(latitude: latitude, longitude: longitude, apiKey: apiKey) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        guard let url = APIEndpoints.citySearchURL(query: query, apiKey: apiKey) else {
            completion([])
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([CityResponse].self, from: data)
                let cities = decoded.map { City(name: $0.name, country: $0.country, coordinates: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)) }
                DispatchQueue.main.async {
                    completion(cities)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
