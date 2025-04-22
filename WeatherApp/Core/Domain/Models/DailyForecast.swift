import Foundation

struct DailyForecast: Codable, Identifiable {
    let dt: Int
    let temp: DailyTemp
    let weather: [WeatherCondition]
    let pop: Double
    let sunrise: Int
    
    var id: Int { dt }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}

struct DailyTemp: Codable {
    let day: Double
    let min: Double
    let max: Double
}
