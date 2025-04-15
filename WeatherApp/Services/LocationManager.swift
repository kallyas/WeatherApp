import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var isLoading = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
    }
}
