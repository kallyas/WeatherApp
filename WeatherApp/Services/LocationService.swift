//
//  LocationService 2.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//


//
//  LocationService.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//

import Foundation
import CoreLocation

class LocationService {
    private let locationManager = LocationManager()
    
    var currentLocation: CLLocation? {
        return locationManager.location
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        // Declare a variable to hold the observer
        var observerRef: Any?
        
        // Create the observer and assign it to the variable
        observerRef = NotificationCenter.default.addObserver(
            forName: .locationUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Remove the observer once we get a result
            if let observer = observerRef as? NSObjectProtocol {
                NotificationCenter.default.removeObserver(observer)
            }
            
            if let location = self?.locationManager.location {
                completion(.success(location))
            } else if let error = notification.object as? Error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "LocationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get location"])))
            }
        }
        
        // Request location
        locationManager.requestLocation()
    }
}

// Extension to make sure Notification.Name.locationUpdated is defined
extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
}
