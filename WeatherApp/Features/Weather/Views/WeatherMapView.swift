import SwiftUI
import MapKit



// Main WeatherMapView
struct WeatherMapView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedMapType: MapDisplayType = .temperature
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    @State private var isMapOptionsVisible = false
    @State private var isLoading = false
    
    enum MapDisplayType: String, CaseIterable, Identifiable {
        case temperature = "Temperature"
        case precipitation = "Precipitation"
        case clouds = "Clouds"
        case wind = "Wind"
        case pressure = "Pressure"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .temperature: return "thermometer"
            case .precipitation: return "cloud.rain"
            case .clouds: return "cloud"
            case .wind: return "wind"
            case .pressure: return "gauge"
            }
        }
        
        var imageOverlayName: String {
            switch self {
            case .temperature: return "temp_map_overlay"
            case .precipitation: return "precip_map_overlay"
            case .clouds: return "cloud_map_overlay"
            case .wind: return "wind_map_overlay"
            case .pressure: return "pressure_map_overlay"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map view with conditional behavior for iOS version
                if #available(iOS 17.0, *) {
                    ios17MapView
                } else {
                    ios16MapView
                }
                
                // Map Options Panel
                mapOptionsPanel
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 80, height: 80)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                }
                
                // Map controls
                mapControlsView
            }
            .navigationTitle("Weather Map")
            .onAppear {
                checkLocationAndLoadMap()
            }
        }
    }
    
    // MARK: - Map Views
    
    // iOS 16 Map View implementation
    private var ios16MapView: some View {
        Map(coordinateRegion: $mapRegion)
            .ignoresSafeArea(edges: .bottom)
            .overlay(weatherOverlayView)
    }
    
    // iOS 17+ Map View implementation
    @available(iOS 17.0, *)
    private var ios17MapView: some View {
        Map(position: mapPositionBinding)
            .ignoresSafeArea(edges: .bottom)
            .mapStyle(.standard)
            .overlay(weatherOverlayView)
    }
    
    // Weather overlay view
    private var weatherOverlayView: some View {
        ZStack {
            weatherTypeOverlay
                .opacity(0.7)
        }
    }
    
    // Weather type specific overlay
    @ViewBuilder
    private var weatherTypeOverlay: some View {
        switch selectedMapType {
        case .temperature:
            Rectangle().fill(temperatureGradient).blendMode(.normal)
        case .precipitation:
            Rectangle().fill(precipitationGradient).blendMode(.normal)
        case .clouds:
            Rectangle().fill(cloudGradient).blendMode(.normal)
        case .wind:
            Rectangle().fill(windGradient).blendMode(.normal)
        case .pressure:
            Rectangle().fill(pressureGradient).blendMode(.normal)
        }
    }
    
    // Map controls
    private var mapControlsView: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 15) {
                    // Toggle map options panel
                    Button(action: {
                        withAnimation {
                            isMapOptionsVisible.toggle()
                        }
                    }) {
                        Image(systemName: isMapOptionsVisible ? "xmark" : "slider.horizontal.3")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(themeManager.accentColor))
                            .shadow(radius: 5)
                    }
                    
                    // Find user location
                    Button(action: {
                        withAnimation {
                            centerOnUserLocation()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(themeManager.accentColor))
                            .shadow(radius: 5)
                    }
                    
                    // Zoom in
                    Button(action: {
                        withAnimation {
                            zoomIn()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(themeManager.accentColor))
                            .shadow(radius: 5)
                    }
                    
                    // Zoom out
                    Button(action: {
                        withAnimation {
                            zoomOut()
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(themeManager.accentColor))
                            .shadow(radius: 5)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Map Options Panel
    
    private var mapOptionsPanel: some View {
        VStack {
            if isMapOptionsVisible {
                VStack(spacing: 0) {
                    // Panel header
                    Text("Map Layers")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                    
                    Divider()
                    
                    // Map type selector list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(MapDisplayType.allCases) { mapType in
                                Button(action: {
                                    selectedMapType = mapType
                                    simulateMapLayerLoading()
                                }) {
                                    mapTypeRow(mapType)
                                }
                                
                                if mapType != MapDisplayType.allCases.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Legend for current map type
                    mapLegend
                }
                .frame(maxWidth: .infinity, maxHeight: 400)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
    }
    
    // Map type row for the selector list
    private func mapTypeRow(_ mapType: MapDisplayType) -> some View {
        HStack {
            Image(systemName: mapType.icon)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 30)
            
            Text(mapType.rawValue)
                .foregroundColor(.primary)
            
            Spacer()
            
            if selectedMapType == mapType {
                Image(systemName: "checkmark")
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    // MARK: - Map Legends
    
    // Legend for the selected map type
    private var mapLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Group {
                switch selectedMapType {
                case .temperature:
                    temperatureLegend
                case .precipitation:
                    precipitationLegend
                case .clouds:
                    cloudLegend
                case .wind:
                    windLegend
                case .pressure:
                    pressureLegend
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
    
    // Temperature legend
    private var temperatureLegend: some View {
        HStack {
            Rectangle()
                .fill(temperatureGradient)
                .frame(height: 20)
                .cornerRadius(5)
            
            Spacer(minLength: 20)
            
            Text("-20°C")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("0°C")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("20°C")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("40°C")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // Precipitation legend
    private var precipitationLegend: some View {
        HStack {
            Rectangle()
                .fill(precipitationGradient)
                .frame(height: 20)
                .cornerRadius(5)
            
            Spacer(minLength: 20)
            
            Text("0 mm")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("5 mm")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("10 mm")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("20+ mm")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // Cloud coverage legend
    private var cloudLegend: some View {
        HStack {
            Rectangle()
                .fill(cloudGradient)
                .frame(height: 20)
                .cornerRadius(5)
            
            Spacer(minLength: 20)
            
            Text("0%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("25%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("50%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("100%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // Wind speed legend
    private var windLegend: some View {
        HStack {
            Rectangle()
                .fill(windGradient)
                .frame(height: 20)
                .cornerRadius(5)
            
            Spacer(minLength: 20)
            
            Text("0 km/h")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("20 km/h")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("40 km/h")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("60+ km/h")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // Pressure legend
    private var pressureLegend: some View {
        HStack {
            Rectangle()
                .fill(pressureGradient)
                .frame(height: 20)
                .cornerRadius(5)
            
            Spacer(minLength: 20)
            
            Text("960 hPa")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("1000 hPa")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("1040 hPa")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Gradients
    
    // Temperature gradient (blue-green-yellow-orange-red)
    private var temperatureGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .green, .yellow, .orange, .red]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Precipitation gradient (clear-blue-purple)
    private var precipitationGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .blue.opacity(0.3), .blue, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Cloud coverage gradient (clear-gray-darkGray)
    private var cloudGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .gray.opacity(0.3), .gray, .gray.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Wind speed gradient (green-yellow-orange-red)
    private var windGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Pressure gradient (purple-blue-cyan-green-yellow)
    private var pressureGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.purple, .blue, .cyan, .green, .yellow]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Helper Methods
    
    // Initialize the map with user location
    private func checkLocationAndLoadMap() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // TODO: Replace with CLLocationManager for real location
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
            isLoading = false
        }
    }
    
    // Center map on user location
    private func centerOnUserLocation() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // TODO: Replace with CLLocationManager for real location
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
            isLoading = false
        }
    }
    
    // Simulate loading when changing map layers
    private func simulateMapLayerLoading() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
        }
    }
    
    // Zoom in function - halves the span
    private func zoomIn() {
        mapRegion = MKCoordinateRegion(
            center: mapRegion.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(mapRegion.span.latitudeDelta * 0.5, 0.01),
                longitudeDelta: max(mapRegion.span.longitudeDelta * 0.5, 0.01)
            )
        )
    }
    
    // Zoom out function - doubles the span
    private func zoomOut() {
        mapRegion = MKCoordinateRegion(
            center: mapRegion.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(mapRegion.span.latitudeDelta * 2, 180),
                longitudeDelta: min(mapRegion.span.longitudeDelta * 2, 180)
            )
        )
    }
}

// MARK: - iOS 17 Map Extensions

@available(iOS 17.0, *)
extension WeatherMapView {
    // Binding to convert between MKCoordinateRegion and MapCameraPosition
    var mapPositionBinding: Binding<MapCameraPosition> {
        return Binding(
            get: {
                MapCameraPosition.region(self.mapRegion)
            },
            set: { newValue in
                DispatchQueue.main.async {
                               print("Not Implemented")
                            }
            }
        )
    }
    
//    // Process new map position safely
//    private func processNewMapPosition(_ position: MapCameraPosition) {
//        // Case 1: If it's a region, extract and assign
//        if case let .region(newRegion) = position {
//            self.mapRegion = newRegion
//            return
//        }
//
//        // Case 2: If it's a camera, extract and convert
//        if case let .camera(camera) = position {
//            let distance = camera.distance
//            let spanDelta = distance / 111_000.0 // Approx. meters to degrees
//            self.mapRegion = MKCoordinateRegion(
//                center: camera.centerCoordinate,
//                span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
//            )
//            return
//        }
//
//        // Fallback: Unhandled position type
//        print("Unhandled MapCameraPosition case: \(position)")
//    }

}

