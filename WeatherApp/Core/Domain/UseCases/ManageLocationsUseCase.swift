//
//  ManageLocationsUseCase.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//
import SwiftUI
import CoreLocation

protocol ManageLocationsUseCaseProtocol {
    func getFavoriteLocations() -> [SavedLocation]
    func getRecentLocations() -> [SavedLocation]
    func addToFavorites(_ location: SavedLocation)
    func removeFromFavorites(_ locationId: String)
    func clearRecentLocations()
    func addToRecentLocations(_ location: SavedLocation) 
}

class ManageLocationsUseCase: ManageLocationsUseCaseProtocol {
    // Using UserDefaults for simplicity, but should use a proper storage solution for a real app
    private let favoriteLocationsKey = "favoriteLocations"
    private let recentLocationsKey = "recentLocations"
    
    private let userDefaults = UserDefaults.standard
    
    func getFavoriteLocations() -> [SavedLocation] {
        guard let data = userDefaults.data(forKey: favoriteLocationsKey),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return []
        }
        return locations
    }
    
    func getRecentLocations() -> [SavedLocation] {
        guard let data = userDefaults.data(forKey: recentLocationsKey),
              let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return []
        }
        return locations
    }
    
    func addToFavorites(_ location: SavedLocation) {
        var favorites = getFavoriteLocations()
        
        // Check if already exists to avoid duplicates
        if !favorites.contains(where: { $0.id == location.id }) {
            favorites.append(location)
            
            if let encoded = try? JSONEncoder().encode(favorites) {
                userDefaults.set(encoded, forKey: favoriteLocationsKey)
            }
        }
    }
    
    func removeFromFavorites(_ locationId: String) {
        var favorites = getFavoriteLocations()
        favorites.removeAll(where: { $0.id == locationId })
        
        if let encoded = try? JSONEncoder().encode(favorites) {
            userDefaults.set(encoded, forKey: favoriteLocationsKey)
        }
    }
    
    func addToRecentLocations(_ location: SavedLocation) {
        var recents = getRecentLocations()
        
        // Remove if it already exists to avoid duplicates
        recents.removeAll(where: { $0.id == location.id })
        
        // Insert at the beginning
        recents.insert(location, at: 0)
        
        // Limit to 10 recent locations
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(recents) {
            userDefaults.set(encoded, forKey: recentLocationsKey)
        }
    }
    
    func clearRecentLocations() {
        userDefaults.removeObject(forKey: recentLocationsKey)
    }
}
