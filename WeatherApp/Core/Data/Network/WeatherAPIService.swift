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
        
        print("WeatherAPIService initialized with API key: \(apiKey)")
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        guard let weatherURL = APIEndpoints.weatherURL(latitude: latitude, longitude: longitude, apiKey: apiKey),
              let forecastURL = APIEndpoints.forecastURL(latitude: latitude, longitude: longitude, apiKey: apiKey) else {
            print("Failed to create weather URL")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("Fetching weather from: \(weatherURL)")
        print("Fetching forecast from: \(forecastURL)")
        
        // First, fetch current weather
        let currentWeatherPublisher = session.dataTaskPublisher(for: weatherURL)
            .tryMap { response -> Data in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("Weather API response status code: \(httpResponse.statusCode)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    return response.data
                } else if httpResponse.statusCode == 401 {
                    print("Authentication error - likely invalid API key")
                    throw URLError(.userAuthenticationRequired)
                } else {
                    print("Server error: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
            }
            
        // Then, fetch 5-day forecast
        let forecastPublisher = session.dataTaskPublisher(for: forecastURL)
            .tryMap { response -> Data in
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("Forecast API response status code: \(httpResponse.statusCode)")
                
                if (200...299).contains(httpResponse.statusCode) {
                    return response.data
                } else {
                    print("Failed to fetch forecast data: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
            }
            .catch { error -> AnyPublisher<Data, Error> in
                // If forecast fails, continue with just the weather data
                print("Forecast fetch failed, continuing with weather only: \(error.localizedDescription)")
                return Just(Data()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
        
        // Combine both publishers
        return Publishers.CombineLatest(currentWeatherPublisher, forecastPublisher)
            .tryMap { weatherData, forecastData in
                do {
                    // Use the adapter to convert to our model format
                    return try WeatherResponseAdapter.adaptCurrentWeatherResponse(weatherData, forecastData)
                } catch {
                    print("Failed to adapt weather response: \(error)")
                    throw error
                }
            }
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    print("JSON decoding error: \(decodingError)")
                    return error
                } else {
                    print("Network error: \(error.localizedDescription)")
                    return error
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = APIEndpoints.citySearchURL(query: safeQuery, apiKey: apiKey) else {
            print("Failed to create city search URL")
            completion([])
            return
        }
        
        print("Searching city: \(safeQuery)")
        
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("City search network error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response format")
                completion([])
                return
            }
            
            print("City search API response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode), let data = data else {
                if httpResponse.statusCode == 401 {
                    print("Authentication error - check API key")
                } else {
                    print("Server error: \(httpResponse.statusCode)")
                }
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([CityResponse].self, from: data)
                let cities = decoded.map { City(name: $0.name, country: $0.country, coordinates: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)) }
                print("Found \(cities.count) cities for query: \(query)")
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
