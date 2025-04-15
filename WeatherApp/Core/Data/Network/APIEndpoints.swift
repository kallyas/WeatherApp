import Foundation

enum APIEndpoints {
    static let baseURL = "https://api.openweathermap.org/data/3.0"
    static let geoURL = "https://api.openweathermap.org/geo/1.0"
    
    static func weatherURL(latitude: Double, longitude: Double, apiKey: String) -> URL? {
        return URL(string: "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)")
    }
    
    static func citySearchURL(query: String, apiKey: String) -> URL? {
        return URL(string: "\(geoURL)/direct?q=\(query)&limit=5&appid=\(apiKey)")
    }
}
