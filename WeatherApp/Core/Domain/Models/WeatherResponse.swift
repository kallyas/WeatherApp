import Foundation

struct WeatherResponse: Codable {
    let current: CurrentWeather
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let timezone: String
    
    enum CodingKeys: String, CodingKey {
        case current, hourly, daily, timezone
    }
}
