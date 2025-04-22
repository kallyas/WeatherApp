//
//  NetworkMonitorServiceProtocol.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//


import Foundation
import Network
import Combine

protocol NetworkMonitorServiceProtocol {
    var isConnected: Bool { get }
    var connectionType: String { get }
    var networkStatusPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

class NetworkMonitorService: NetworkMonitorServiceProtocol {
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")
    private let connectionStatusSubject = CurrentValueSubject<Bool, Never>(false)
    
    private(set) var isConnected: Bool = false {
        didSet {
            connectionStatusSubject.send(isConnected)
        }
    }
    
    private(set) var connectionType: String = "Unknown"
    
    var networkStatusPublisher: AnyPublisher<Bool, Never> {
        return connectionStatusSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        networkMonitor.start(queue: monitorQueue)
    }
    
    func stopMonitoring() {
        networkMonitor.cancel()
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(with: path)
            }
        }
    }
    
    private func updateConnectionStatus(with path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            connectionType = "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = "Ethernet"
        } else {
            connectionType = "Unknown"
        }
        
        notifyNetworkStatusChange()
    }
    
    private func notifyNetworkStatusChange() {
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: ["isConnected": isConnected, "connectionType": connectionType]
        )
        
        print("Network status: \(isConnected ? "Connected" : "Disconnected") via \(connectionType)")
    }
}

// Notification name extension
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}