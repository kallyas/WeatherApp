import Foundation

enum APIEndpoints {
    static let baseURL = AppConfiguration.baseURL
    static let geoURL = AppConfiguration.geoURL
    
    static func weatherURL(latitude: Double, longitude: Double, apiKey: String) -> URL? {
        // Updated to use the proper endpoint from the documentation
        var components = URLComponents(string: "\(baseURL)/weather")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "units", value: AppConfiguration.defaultTempUnit),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        return components?.url
    }
    
    static func forecastURL(latitude: Double, longitude: Double, apiKey: String) -> URL? {
        // Added the 5-day forecast endpoint
        var components = URLComponents(string: "\(baseURL)/forecast")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "units", value: AppConfiguration.defaultTempUnit),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        return components?.url
    }
    
    static func citySearchURL(query: String, apiKey: String) -> URL? {
        var components = URLComponents(string: "\(geoURL)/direct")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        return components?.url
    }
}
