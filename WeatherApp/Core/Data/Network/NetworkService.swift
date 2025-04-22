import Foundation
import Combine
import CoreLocation

class NetworkService {
    // Use AppConfiguration instead of hardcoded values
    private let apiKey = AppConfiguration.apiKey
    private let baseURL = AppConfiguration.baseURL
    private let geoURL = AppConfiguration.geoURL
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        guard let url = URL(string: "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&units=\(AppConfiguration.defaultTempUnit)&appid=\(apiKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("Fetching weather from URL: \(url)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { response -> Data in
                print("Received data of size: \(response.data.count) bytes")
                return response.data
            }
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(geoURL)/direct?q=\(encodedQuery)&limit=5&appid=\(apiKey)") else {
            completion([])
            return
        }
        
        print("Searching city with URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("City search error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([CityResponse].self, from: data)
                let cities = decoded.map { City(name: $0.name, country: $0.country, coordinates: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)) }
                print("Found \(cities.count) cities")
                DispatchQueue.main.async {
                    completion(cities)
                }
            } catch {
                print("JSON decoding error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
