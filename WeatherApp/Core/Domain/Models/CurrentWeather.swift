import Foundation

struct CurrentWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let weather: [WeatherCondition]
    let uvi: Double
    let visibility: Int
    let pressure: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case weather
        case uvi
        case visibility
        case pressure
    }
}
