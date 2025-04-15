import Foundation

struct HourlyForecast: Codable, Identifiable {
    let dt: Int
    let temp: Double
    let weather: [WeatherCondition]
    
    var id: Int { dt }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}
