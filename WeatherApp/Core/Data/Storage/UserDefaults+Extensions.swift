import Foundation
import CoreLocation

extension UserDefaults {
    private enum Keys {
        static let isDarkMode = "isDarkMode"
        static let lastViewedCity = "lastViewedCity"
    }
    
    var isDarkMode: Bool {
        get { bool(forKey: Keys.isDarkMode) }
        set { set(newValue, forKey: Keys.isDarkMode) }
    }
    
    func saveLastViewedCity(cityName: String, latitude: Double, longitude: Double, country: String) {
        let cityDict: [String: Any] = [
            "name": cityName,
            "latitude": latitude,
            "longitude": longitude,
            "country": country
        ]
        set(cityDict, forKey: Keys.lastViewedCity)
    }
    
    func getLastViewedCity() -> City? {
        guard let cityDict = dictionary(forKey: Keys.lastViewedCity) else { return nil }
        
        guard let name = cityDict["name"] as? String,
              let latitude = cityDict["latitude"] as? Double,
              let longitude = cityDict["longitude"] as? Double,
              let country = cityDict["country"] as? String else { return nil }
        
        return City(
            name: name,
            country: country,
            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}
