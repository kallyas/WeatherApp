//
//  WeatherCacheService.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//

import Foundation
import CoreLocation

protocol WeatherCacheServiceProtocol {
    func getCachedWeather(for coordinates: CLLocationCoordinate2D) -> WeatherResponse?
    func cacheWeather(_ weather: WeatherResponse, for coordinates: CLLocationCoordinate2D)
    func clearCache()
}

class WeatherCacheService: WeatherCacheServiceProtocol {
    private var cache = NSCache<NSString, CacheEntry>()
    private let cacheDuration: TimeInterval
    private let fileManager = FileManager.default
    private let cacheDirectoryName = "WeatherCache"
    
    // Changed from struct to class and inherits from NSObject
    class CacheEntry: NSObject {
        let timestamp: Date
        let weather: WeatherResponse
        
        init(timestamp: Date, weather: WeatherResponse) {
            self.timestamp = timestamp
            self.weather = weather
            super.init()
        }
    }
    
    init(cacheDuration: TimeInterval = 30 * 60) { // Default 30 minutes
        self.cacheDuration = cacheDuration
        setupCacheDirectory()
        loadCacheFromDisk()
    }
    
    func getCachedWeather(for coordinates: CLLocationCoordinate2D) -> WeatherResponse? {
        let key = cacheKey(for: coordinates)
        
        // Try memory cache first
        if let entry = cache.object(forKey: key as NSString) {
            // Check if cache is still valid
            if Date().timeIntervalSince(entry.timestamp) <= cacheDuration {
                return entry.weather
            } else {
                // Remove expired cache entry
                cache.removeObject(forKey: key as NSString)
                removeCacheFile(for: key)
                return nil
            }
        }
        
        // If not in memory, try loading from disk
        return loadWeatherFromDisk(for: key)
    }
    
    func cacheWeather(_ weather: WeatherResponse, for coordinates: CLLocationCoordinate2D) {
        let key = cacheKey(for: coordinates)
        let entry = CacheEntry(timestamp: Date(), weather: weather)
        
        // Cache in memory
        cache.setObject(entry, forKey: key as NSString)
        
        // Cache to disk
        saveWeatherToDisk(weather, timestamp: entry.timestamp, for: key)
    }
    
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        do {
            let cacheURL = try cacheDirectoryURL()
            try fileManager.removeItem(at: cacheURL)
            setupCacheDirectory() // Recreate the directory
        } catch {
            print("Error clearing cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func cacheKey(for coordinates: CLLocationCoordinate2D) -> String {
        // Round coordinates to 2 decimal places to avoid slight variations
        let roundedLat = round(coordinates.latitude * 100) / 100
        let roundedLon = round(coordinates.longitude * 100) / 100
        return "weather_\(roundedLat)_\(roundedLon)"
    }
    
    private func setupCacheDirectory() {
        do {
            let cacheURL = try cacheDirectoryURL()
            if !fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error setting up cache directory: \(error.localizedDescription)")
        }
    }
    
    private func cacheDirectoryURL() throws -> URL {
        return try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cacheDirectoryName)
    }
    
    private func cacheFileURL(for key: String) throws -> URL {
        return try cacheDirectoryURL().appendingPathComponent("\(key).cache")
    }
    
    private func saveWeatherToDisk(_ weather: WeatherResponse, timestamp: Date, for key: String) {
        do {
            let cacheData = CacheDiskData(timestamp: timestamp, weather: weather)
            let data = try JSONEncoder().encode(cacheData)
            let fileURL = try cacheFileURL(for: key)
            try data.write(to: fileURL)
        } catch {
            print("Error saving weather to disk: \(error.localizedDescription)")
        }
    }
    
    private func loadWeatherFromDisk(for key: String) -> WeatherResponse? {
        do {
            let fileURL = try cacheFileURL(for: key)
            
            // Check if file exists
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            let data = try Data(contentsOf: fileURL)
            let cacheData = try JSONDecoder().decode(CacheDiskData.self, from: data)
            
            // Check if cache has expired
            if Date().timeIntervalSince(cacheData.timestamp) <= cacheDuration {
                // Add to memory cache and return
                let entry = CacheEntry(timestamp: cacheData.timestamp, weather: cacheData.weather)
                cache.setObject(entry, forKey: key as NSString)
                return cacheData.weather
            } else {
                // Remove expired cache file
                removeCacheFile(for: key)
                return nil
            }
        } catch {
            print("Error loading weather from disk: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func removeCacheFile(for key: String) {
        do {
            let fileURL = try cacheFileURL(for: key)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error removing cache file: \(error.localizedDescription)")
        }
    }
    
    private func loadCacheFromDisk() {
        do {
            let cacheURL = try cacheDirectoryURL()
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                guard fileURL.pathExtension == "cache" else { continue }
                
                let key = fileURL.deletingPathExtension().lastPathComponent
                
                if loadWeatherFromDisk(for: key) != nil {
                    // Successfully loaded valid cache entry
                    print("Loaded cache from disk: \(key)")
                }
            }
        } catch {
            print("Error loading cache from disk: \(error.localizedDescription)")
        }
    }
}

// Structure for disk storage
private struct CacheDiskData: Codable {
    let timestamp: Date
    let weather: WeatherResponse
}
