import SwiftUI
import MapKit

struct WeatherMapView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedMapType: MapDisplayType = .temperature
    @State private var region = MKCoordinateRegion(
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
                // Map view
                Map(coordinateRegion: $region)
                    .edgesIgnoringSafeArea(.bottom)
                    .overlay(
                        // Weather overlay image (would be from API in real app)
                        Image("weather_map_placeholder")
                            .resizable()
                            .opacity(0.7)
                            .overlay(
                                // This is a placeholder overlay based on selected type
                                weatherOverlay
                            )
                    )
                
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
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 15) {
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
                            
                            Button(action: {
                                withAnimation {
                                    // Find user location
                                    isLoading = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        // In a real app, this would use LocationManager
                                        region.center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                                        isLoading = false
                                    }
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(themeManager.accentColor))
                                    .shadow(radius: 5)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    // Zoom in
                                    region.span.latitudeDelta = max(region.span.latitudeDelta * 0.5, 0.01)
                                    region.span.longitudeDelta = max(region.span.longitudeDelta * 0.5, 0.01)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(themeManager.accentColor))
                                    .shadow(radius: 5)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    // Zoom out
                                    region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 180)
                                    region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 180)
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
            .navigationTitle("Weather Map")
            .onAppear {
                // In a real app, load the user's last position or current location
                checkLocationAndLoadMap()
            }
        }
    }
    
    // Weather overlay based on selected map type
    private var weatherOverlay: some View {
        ZStack {
            // In a real app, this would display actual weather data as an overlay
            // Here we just show different colored overlays for different map types
            switch selectedMapType {
            case .temperature:
                temperatureGradient.opacity(0.4)
            case .precipitation:
                precipitationGradient.opacity(0.5)
            case .clouds:
                cloudGradient.opacity(0.3)
            case .wind:
                windGradient.opacity(0.4)
            case .pressure:
                pressureGradient.opacity(0.4)
            }
        }
    }
    
    // Map options panel that slides in/out
    private var mapOptionsPanel: some View {
        VStack {
            if isMapOptionsVisible {
                VStack(spacing: 0) {
                    Text("Map Layers")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(MapDisplayType.allCases) { mapType in
                                Button(action: {
                                    selectedMapType = mapType
                                    // In a real app, refresh the weather overlay
                                    withAnimation {
                                        isLoading = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            isLoading = false
                                        }
                                    }
                                }) {
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
    
    // Legend for the selected map type
    private var mapLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
    
    // Each map type has its own legend
    private var temperatureLegend: some View {
        HStack {
            temperatureGradient
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
    
    private var precipitationLegend: some View {
        HStack {
            precipitationGradient
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
    
    private var cloudLegend: some View {
        HStack {
            cloudGradient
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
    
    private var windLegend: some View {
        HStack {
            windGradient
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
    
    private var pressureLegend: some View {
        HStack {
            pressureGradient
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
    
    // Gradients for each map type
    private var temperatureGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .green, .yellow, .orange, .red]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var precipitationGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .blue.opacity(0.3), .blue, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var cloudGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .gray.opacity(0.3), .gray, .gray.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var windGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var pressureGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.purple, .blue, .cyan, .green, .yellow]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Helper Methods
    
    private func checkLocationAndLoadMap() {
        // In a real app, this would use LocationManager to get user's location
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulating location loading
            // In a real app, this would set region to the user's actual location
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
            isLoading = false
        }
    }
}

// Preview
struct WeatherMapView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherMapView()
    }
}