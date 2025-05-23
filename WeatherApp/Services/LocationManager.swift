import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var isLoading = false
    @Published var locationError: LocationError?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var hasRequestedAuthorization = false
    
    // Timer for automatic location updates
    private var locationUpdateTimer: Timer?
    private let updateInterval: TimeInterval = 10 * 60 // 10 minutes
    
    enum LocationError: Error, Identifiable {
        case denied
        case restricted
        case unknown(Error)
        case locationUnknown
        case timeout
        
        var id: String {
            switch self {
            case .denied: return "denied"
            case .restricted: return "restricted"
            case .unknown: return "unknown"
            case .locationUnknown: return "locationUnknown"
            case .timeout: return "timeout"
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
                return "Unable to determine location. Please check your internet connection and try again."
            case .timeout:
                return "Location request timed out. Please try again."
            }
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        
        // Print current status to help with debugging
        print("Initial location authorization status: \(manager.authorizationStatus.rawValue)")
    }
    
    deinit {
        stopLocationUpdates()
    }
    
    func requestLocation() {
        // Only proceed if we haven't already requested authorization
        // This prevents the loop of repeatedly requesting permission
        if manager.authorizationStatus == .notDetermined && hasRequestedAuthorization {
            print("Already requested authorization, waiting for user response...")
            return
        }
        
        isLoading = true
        locationError = nil
        
        print("Requesting location - current authorization: \(manager.authorizationStatus.rawValue)")
        
        // Set a timeout for location request
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isLoading {
                self.isLoading = false
                self.locationError = .timeout
                print("Location request timed out")
            }
        }
        
        switch manager.authorizationStatus {
        case .notDetermined:
            // First time request - prompt the user
            print("Location authorization not determined - requesting permission")
            hasRequestedAuthorization = true
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, request location
            print("Location authorized - requesting current location")
            manager.requestLocation()
            
        case .denied:
            // User denied access
            isLoading = false
            locationError = .denied
            timeoutTimer.invalidate()
            print("Location access denied by user")
            
        case .restricted:
            // User cannot change this authorization status
            isLoading = false
            locationError = .restricted
            timeoutTimer.invalidate()
            print("Location access restricted")
            
        @unknown default:
            isLoading = false
            let error = NSError(domain: "Unknown authorization status", code: 0)
            locationError = .unknown(error)
            timeoutTimer.invalidate()
            print("Unknown location authorization status")
        }
    }
    
    func startPeriodicLocationUpdates() {
        stopLocationUpdates() // Stop any existing timer
        
        // Start a new timer to update location periodically
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            if self?.manager.authorizationStatus == .authorizedWhenInUse ||
               self?.manager.authorizationStatus == .authorizedAlways {
                print("Requesting periodic location update")
                self?.manager.requestLocation()
            }
        }
    }
    
    func stopLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // If we need to force the prompt again
    func resetAuthorizationRequest() {
        hasRequestedAuthorization = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        
        guard let location = locations.last else {
            locationError = .locationUnknown
            print("Location update failed: No locations found")
            return
        }
        
        // Check if location is valid (not 0,0 and not too old)
        let coordinates = location.coordinate
        if coordinates.latitude == 0 && coordinates.longitude == 0 {
            locationError = .locationUnknown
            print("Invalid location received (0,0)")
            return
        }
        
        // Check if location is recent enough (within the last 5 minutes)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        if location.timestamp < fiveMinutesAgo {
            locationError = .locationUnknown
            print("Location is too old: \(location.timestamp)")
            return
        }
        
        self.location = location
        print("Location obtained successfully: \(coordinates.latitude), \(coordinates.longitude)")
        
        // Post notification that location was updated
        NotificationCenter.default.post(name: .locationUpdated, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        
        print("Location manager failed with error: \(error.localizedDescription)")
        
        // Handle specific error codes
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
                print("Location access denied")
            case .locationUnknown:
                locationError = .locationUnknown
                print("Location unknown")
            default:
                locationError = .unknown(error)
                print("CLError code: \(clError.code.rawValue)")
            }
        } else {
            locationError = .unknown(error)
        }
        
        // Post notification that location update failed
        NotificationCenter.default.post(name: .locationUpdated, object: error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        authorizationStatus = newStatus
        print("Authorization status changed to: \(newStatus.rawValue)")
        
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if isLoading {
                print("Authorization granted, requesting location...")
                manager.requestLocation()
            }
        case .denied:
            isLoading = false
            locationError = .denied
            print("Location authorization denied")
        case .restricted:
            isLoading = false
            locationError = .restricted
            print("Location authorization restricted")
        case .notDetermined:
            print("Location authorization not determined")
        @unknown default:
            isLoading = false
            let error = NSError(domain: "Unknown authorization status", code: 0)
            locationError = .unknown(error)
            print("Unknown authorization status")
        }
    }
}
