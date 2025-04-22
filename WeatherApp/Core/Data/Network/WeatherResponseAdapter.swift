import Foundation
import Combine

// This adapter converts the response from current weather API (2.5) format 
// to match the structure expected by our app (which was designed for API 3.0)
class WeatherResponseAdapter {
    
    // Convert from OpenWeather API 2.5 current weather response to our app's model
    static func adaptCurrentWeatherResponse(_ currentWeatherData: Data, _ forecastData: Data? = nil) throws -> WeatherResponse {
        let decoder = JSONDecoder()
        
        // Decode current weather
        let currentWeatherResponse = try decoder.decode(OpenWeatherCurrentResponse.self, from: currentWeatherData)
        
        // Create a current weather object
        let current = CurrentWeather(
            temp: currentWeatherResponse.main.temp,
            feelsLike: currentWeatherResponse.main.feels_like,
            humidity: currentWeatherResponse.main.humidity,
            windSpeed: currentWeatherResponse.wind.speed,
            weather: currentWeatherResponse.weather,
            uvi: 0, // Not available in basic API
            visibility: currentWeatherResponse.visibility,
            pressure: currentWeatherResponse.main.pressure
        )
        
        // Default empty arrays for hourly and daily forecasts
        var hourly: [HourlyForecast] = []
        var daily: [DailyForecast] = []
        
        // If we have forecast data, parse it
        if let forecastData = forecastData {
            let forecastResponse = try decoder.decode(OpenWeatherForecastResponse.self, from: forecastData)
            
            // Convert list items to hourly forecasts (first 24 entries = 3 days with 3-hour intervals)
            hourly = forecastResponse.list.prefix(24).map { item in
                HourlyForecast(
                    dt: item.dt,
                    temp: item.main.temp,
                    weather: item.weather
                )
            }
            
            // Group forecast data by day for daily forecasts
            let calendar = Calendar.current
            let groupedByDay = Dictionary(grouping: forecastResponse.list) { item in
                let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
                return calendar.startOfDay(for: date)
            }
            
            // Convert grouped data to daily forecasts
            daily = groupedByDay.keys.sorted().map { date in
                let dayItems = groupedByDay[date]!
                
                // Get min and max temps for the day
                let temps = dayItems.map { $0.main.temp }
                let minTemp = temps.min() ?? 0
                let maxTemp = temps.max() ?? 0
                
                // Get most common weather condition for the day
                let allWeatherConditions = dayItems.flatMap { $0.weather }
                let mostCommonWeather = allWeatherConditions.first ?? WeatherCondition(id: 800, main: "Clear", description: "clear sky", icon: "01d")
                
                // Calculate precipitation probability (if available)
                let pop = dayItems.compactMap { $0.pop }.max() ?? 0
                
                return DailyForecast(
                    dt: Int(date.timeIntervalSince1970),
                    temp: DailyTemp(
                        day: dayItems.first?.main.temp ?? 0,
                        min: minTemp,
                        max: maxTemp
                    ),
                    weather: [mostCommonWeather],
                    pop: pop
                )
            }
        }
        
        // Create the complete response
        return WeatherResponse(
            current: current,
            hourly: hourly,
            daily: daily,
            timezone: currentWeatherResponse.name
        )
    }
}

// Models to match the API 2.5 response format
struct OpenWeatherCurrentResponse: Codable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let visibility: Int
    let wind: Wind
    let dt: Int
    let name: String
    
    struct MainWeather: Codable {
        let temp: Double
        let feels_like: Double
        let pressure: Int
        let humidity: Int
        let temp_min: Double
        let temp_max: Double
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int
    }
}

struct OpenWeatherForecastResponse: Codable {
    let list: [ForecastItem]
    let city: City
    
    struct ForecastItem: Codable {
        let dt: Int
        let main: MainWeather
        let weather: [WeatherCondition]
        let pop: Double?
        
        struct MainWeather: Codable {
            let temp: Double
            let feels_like: Double
            let pressure: Int
            let humidity: Int
            let temp_min: Double
            let temp_max: Double
        }
    }
    
    struct City: Codable {
        let name: String
        let country: String
    }
}