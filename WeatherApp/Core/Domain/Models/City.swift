import Foundation
import CoreLocation

struct City: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let coordinates: CLLocationCoordinate2D
    
    var fullName: String {
        "\(name), \(country)"
    }
}

struct CityResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
}
