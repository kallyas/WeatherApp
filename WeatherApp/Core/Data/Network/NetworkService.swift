import Foundation
import Combine
import CoreLocation

class NetworkService {
    private let apiKey = "YOUR_OPENWEATHER_API_KEY" // Replace with your OpenWeather API key
    private let baseURL = "https://api.openweathermap.org/data/3.0"
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        let url = URL(string: "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(query)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
