import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject {
    // Make the manager public so it can be accessed from ContentView
    public let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var isLoading = false
    @Published var locationError: LocationError?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Use a PassthroughSubject for more flexible error handling and updates
    private let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        return authorizationStatusSubject.eraseToAnyPublisher()
    }
    
    enum LocationError: Error, Identifiable {
        case denied
        case restricted
        case unknown(Error)
        case locationUnknown
        
        var id: String {
            switch self {
            case .denied: return "denied"
            case .restricted: return "restricted"
            case .unknown: return "unknown"
            case .locationUnknown: return "locationUnknown"
            }
        }
        
        var description: String {
            switch self {
            case .denied:
                return "Location access has been denied. Please enable it in Settings to use this feature."
            case .restricted:
                return "Location access is restricted. This may be due to parental controls."
            case .unknown(let error):
                return "Location error: \(error.localizedDescription)"
            case .locationUnknown:
                return "Unable to determine location."
            }
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    deinit {
        // Clean up any resources. Not strictly necessary here, but good practice.
        manager.delegate = nil
    }
    
    func requestLocation() {
        isLoading = true
        locationError = nil
        
        print("Authorization status: \(manager.authorizationStatus.rawValue)")
        
        // Check current authorization status
        switch manager.authorizationStatus {
        case .notDetermined:
            // First time request - prompt the user
            print("Requesting authorization...")
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, request location
            print("Already authorized, requesting location...")
            manager.requestLocation()
            
        case .denied:
            // User denied access
            isLoading = false
            locationError = .denied
            print("Location request failed: Denied")
            
        case .restricted:
            // User cannot change this authorization status
            isLoading = false
            locationError = .restricted
            print("Location request failed: Restricted")
            
        @unknown default:
            isLoading = false
            let error = NSError(domain: "Unknown authorization status", code: 0)
            locationError = .unknown(error)
            print("Location request failed: Unknown - \(error.localizedDescription)")
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Authorization check
    func checkAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
        authorizationStatusSubject.send(authorizationStatus) // Send updates
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false // Move this to the beginning of the function
        guard let location = locations.last else {
            // Handle the case where no locations are in the array
            locationError = .locationUnknown
            print("Location update failed: No locations found")
            return
        }
        self.location = location
        print("Got location: \(location)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        
        // Handle specific error codes
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
                print("Location error: Denied")
            case .locationUnknown:
                locationError = .locationUnknown
                print("Location error: Location unknown")
            default:
                locationError = .unknown(error)
                print("Location error: \(error.localizedDescription)")
            }
        } else {
            locationError = .unknown(error)
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        authorizationStatusSubject.send(authorizationStatus) // Send updates
        print("Authorization status changed to: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Only request location if we are already loading
            if isLoading {
                print("Now authorized, requesting location...")
                manager.requestLocation()
            }
        case .denied:
            isLoading = false
            locationError = .denied
            print("Authorization changed: Denied")
        case .restricted:
            isLoading = false
            locationError = .restricted
            print("Authorization changed: Restricted")
        case .notDetermined:
            // Handle the notDetermined case, if needed
            print("Authorization changed: Not determined")
        @unknown default:
            isLoading = false
            let error = NSError(domain: "Unknown authorization status", code: 0)
            locationError = .unknown(error)
            print("Authorization changed: Unknown - \(error.localizedDescription)")
        }
    }
}
