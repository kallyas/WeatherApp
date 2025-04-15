#!/bin/bash

# Setup script for WeatherApp
# This script creates the folder structure and populates key files for the WeatherApp project

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the base directory for the project (current directory)
BASE_DIR="WeatherApp"

echo -e "${BLUE}Creating Weather App folder structure...${NC}"

# Create the main project directory
mkdir -p $BASE_DIR
cd $BASE_DIR

# Create the folder structure
echo -e "${GREEN}Creating directories...${NC}"

# App directory
mkdir -p App

# Core directories
mkdir -p Core/Domain/Models
mkdir -p Core/Domain/UseCases
mkdir -p Core/Data/Network
mkdir -p Core/Data/Repositories
mkdir -p Core/Data/Storage
mkdir -p Core/DI

# Features directories
mkdir -p Features/Common/Extensions
mkdir -p Features/Common/Helpers
mkdir -p Features/Common/Components/WeatherEffects
mkdir -p Features/Welcome/Views
mkdir -p Features/Weather/ViewModels
mkdir -p Features/Weather/Views
mkdir -p Features/Search/ViewModels
mkdir -p Features/Search/Views

# Services, Resources, and Config directories
mkdir -p Services
mkdir -p Resources
mkdir -p Config

echo -e "${GREEN}Folder structure created successfully!${NC}"

# Create and populate main files
echo -e "${BLUE}Creating and populating key files...${NC}"

# App entry point
cat > App/WeatherApp.swift << 'EOF'
import SwiftUI

@main
struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# Core/Domain/Models files
cat > Core/Domain/Models/WeatherResponse.swift << 'EOF'
import Foundation

struct WeatherResponse: Codable {
    let current: CurrentWeather
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let timezone: String
    
    enum CodingKeys: String, CodingKey {
        case current, hourly, daily, timezone
    }
}
EOF

cat > Core/Domain/Models/CurrentWeather.swift << 'EOF'
import Foundation

struct CurrentWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let weather: [WeatherCondition]
    let uvi: Double
    let visibility: Int
    let pressure: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case weather
        case uvi
        case visibility
        case pressure
    }
}
EOF

cat > Core/Domain/Models/HourlyForecast.swift << 'EOF'
import Foundation

struct HourlyForecast: Codable, Identifiable {
    let dt: Int
    let temp: Double
    let weather: [WeatherCondition]
    
    var id: Int { dt }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}
EOF

cat > Core/Domain/Models/DailyForecast.swift << 'EOF'
import Foundation

struct DailyForecast: Codable, Identifiable {
    let dt: Int
    let temp: DailyTemp
    let weather: [WeatherCondition]
    let pop: Double
    
    var id: Int { dt }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}

struct DailyTemp: Codable {
    let day: Double
    let min: Double
    let max: Double
}
EOF

cat > Core/Domain/Models/WeatherCondition.swift << 'EOF'
import Foundation

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}
EOF

cat > Core/Domain/Models/City.swift << 'EOF'
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
EOF

# Core/Domain/UseCases files
cat > Core/Domain/UseCases/FetchWeatherUseCase.swift << 'EOF'
import Foundation
import Combine

protocol FetchWeatherUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
}

class FetchWeatherUseCase: FetchWeatherUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    
    init(weatherRepository: WeatherRepositoryProtocol) {
        self.weatherRepository = weatherRepository
    }
    
    func execute(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        return weatherRepository.fetchWeather(latitude: latitude, longitude: longitude)
    }
}
EOF

cat > Core/Domain/UseCases/SearchCityUseCase.swift << 'EOF'
import Foundation

protocol SearchCityUseCaseProtocol {
    func execute(query: String, completion: @escaping ([City]) -> Void)
}

class SearchCityUseCase: SearchCityUseCaseProtocol {
    private let weatherRepository: WeatherRepositoryProtocol
    
    init(weatherRepository: WeatherRepositoryProtocol) {
        self.weatherRepository = weatherRepository
    }
    
    func execute(query: String, completion: @escaping ([City]) -> Void) {
        weatherRepository.searchCity(query: query, completion: completion)
    }
}
EOF

# Core/Data/Network files
cat > Core/Data/Network/NetworkService.swift << 'EOF'
import Foundation
import Combine

class NetworkService {
    private let apiKey = "YOUR_OPENWEATHER_API_KEY" // Replace with your OpenWeather API key
    private let baseURL = "https://api.openweathermap.org/data/3.0"
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        let url = URL(string: "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(query)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([CityResponse].self, from: data)
                let cities = decoded.map { City(name: $0.name, country: $0.country, coordinates: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)) }
                DispatchQueue.main.async {
                    completion(cities)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
EOF

cat > Core/Data/Network/APIEndpoints.swift << 'EOF'
import Foundation

enum APIEndpoints {
    static let baseURL = "https://api.openweathermap.org/data/3.0"
    static let geoURL = "https://api.openweathermap.org/geo/1.0"
    
    static func weatherURL(latitude: Double, longitude: Double, apiKey: String) -> URL? {
        return URL(string: "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)")
    }
    
    static func citySearchURL(query: String, apiKey: String) -> URL? {
        return URL(string: "\(geoURL)/direct?q=\(query)&limit=5&appid=\(apiKey)")
    }
}
EOF

cat > Core/Data/Network/WeatherAPIService.swift << 'EOF'
import Foundation
import Combine

protocol WeatherAPIServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
    func searchCity(query: String, completion: @escaping ([City]) -> Void)
}

class WeatherAPIService: WeatherAPIServiceProtocol {
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        guard let url = APIEndpoints.weatherURL(latitude: latitude, longitude: longitude, apiKey: apiKey) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        guard let url = APIEndpoints.citySearchURL(query: query, apiKey: apiKey) else {
            completion([])
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([CityResponse].self, from: data)
                let cities = decoded.map { City(name: $0.name, country: $0.country, coordinates: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)) }
                DispatchQueue.main.async {
                    completion(cities)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
EOF

# Core/Data/Repositories files
cat > Core/Data/Repositories/WeatherRepository.swift << 'EOF'
import Foundation
import Combine

protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
    func searchCity(query: String, completion: @escaping ([City]) -> Void)
}

class WeatherRepository: WeatherRepositoryProtocol {
    private let weatherAPIService: WeatherAPIServiceProtocol
    
    init(weatherAPIService: WeatherAPIServiceProtocol) {
        self.weatherAPIService = weatherAPIService
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        return weatherAPIService.fetchWeather(latitude: latitude, longitude: longitude)
    }
    
    func searchCity(query: String, completion: @escaping ([City]) -> Void) {
        weatherAPIService.searchCity(query: query, completion: completion)
    }
}
EOF

# Core/Data/Storage files
cat > Core/Data/Storage/UserDefaults+Extensions.swift << 'EOF'
import Foundation

extension UserDefaults {
    private enum Keys {
        static let isDarkMode = "isDarkMode"
        static let lastViewedCity = "lastViewedCity"
    }
    
    var isDarkMode: Bool {
        get { bool(forKey: Keys.isDarkMode) }
        set { set(newValue, forKey: Keys.isDarkMode) }
    }
    
    func saveLastViewedCity(cityName: String, latitude: Double, longitude: Double, country: String) {
        let cityDict: [String: Any] = [
            "name": cityName,
            "latitude": latitude,
            "longitude": longitude,
            "country": country
        ]
        set(cityDict, forKey: Keys.lastViewedCity)
    }
    
    func getLastViewedCity() -> City? {
        guard let cityDict = dictionary(forKey: Keys.lastViewedCity) else { return nil }
        
        guard let name = cityDict["name"] as? String,
              let latitude = cityDict["latitude"] as? Double,
              let longitude = cityDict["longitude"] as? Double,
              let country = cityDict["country"] as? String else { return nil }
        
        return City(
            name: name,
            country: country,
            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}
EOF

# Core/DI files
cat > Core/DI/AppContainer.swift << 'EOF'
import Foundation

class AppContainer {
    // API Key - Replace with your actual API key
    private let apiKey = "YOUR_OPENWEATHER_API_KEY"
    
    // Services
    lazy var weatherAPIService: WeatherAPIServiceProtocol = {
        return WeatherAPIService(apiKey: apiKey)
    }()
    
    // Repositories
    lazy var weatherRepository: WeatherRepositoryProtocol = {
        return WeatherRepository(weatherAPIService: weatherAPIService)
    }()
    
    // Use Cases
    lazy var fetchWeatherUseCase: FetchWeatherUseCaseProtocol = {
        return FetchWeatherUseCase(weatherRepository: weatherRepository)
    }()
    
    lazy var searchCityUseCase: SearchCityUseCaseProtocol = {
        return SearchCityUseCase(weatherRepository: weatherRepository)
    }()
}
EOF

# Features/Common/Extensions files
cat > Features/Common/Extensions/View+Extensions.swift << 'EOF'
import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Color {
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let darkBackground = Color(red: 0.11, green: 0.11, blue: 0.13)
}
EOF

# Features/Common/Helpers files
cat > Features/Common/Helpers/DateFormatters.swift << 'EOF'
import Foundation

struct DateFormatters {
    static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let shortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}
EOF

# Services files
cat > Services/LocationManager.swift << 'EOF'
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
EOF

# Features/Common/Components files
cat > Features/Common/Components/LoadingView.swift << 'EOF'
import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.fill")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Loading weather data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
EOF

cat > Features/Common/Components/ErrorView.swift << 'EOF'
import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 70))
            
            Text("Oops!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top)
        }
        .padding()
    }
}
EOF

cat > Features/Common/Components/WeatherDataPill.swift << 'EOF'
import SwiftUI

struct WeatherDataPill: View {
    let icon: String
    let title: String
    let value: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDarkMode ? .white : .blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}
EOF

# Features/Common/Components/WeatherEffects files
cat > Features/Common/Components/WeatherEffects/CloudsEffectView.swift << 'EOF'
import SwiftUI

struct CloudsEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<10) { i in
                CloudView(size: CGFloat.random(in: 100...300), opacity: 0.7, isDarkMode: isDarkMode)
                    .offset(x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
                            y: CGFloat.random(in: -200...UIScreen.main.bounds.height))
            }
        }
    }
}

struct CloudView: View {
    let size: CGFloat
    let opacity: Double
    let isDarkMode: Bool
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: size, height: size * 0.6)
            .foregroundColor(isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(opacity))
            .offset(x: offset, y: 0)
            .onAppear {
                withAnimation(Animation.linear(duration: Double.random(in: 60...120)).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.width + size
                }
            }
    }
}
EOF

cat > Features/Common/Components/WeatherEffects/RainEffectView.swift << 'EOF'
import SwiftUI

struct RainEffectView: View {
    let isDarkMode: Bool
    var intensity: RainIntensity = .moderate
    
    enum RainIntensity {
        case light, moderate, heavy
        
        var dropCount: Int {
            switch self {
            case .light: return 30
            case .moderate: return 60
            case .heavy: return 100
            }
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<intensity.dropCount, id: \.self) { i in
                RainDrop(isDarkMode: isDarkMode)
            }
        }
    }
}

struct RainDrop: View {
    let isDarkMode: Bool
    
    @State private var isAnimating = false
    private let startPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: -20
    )
    private let endPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: UIScreen.main.bounds.height + 20
    )
    private let duration = Double.random(in: 0.3...0.8)
    private let delay = Double.random(in: 0...3)
    private let width: CGFloat = CGFloat.random(in: 1...2)
    private let height: CGFloat = CGFloat.random(in: 7...15)
    
    var body: some View {
        Rectangle()
            .fill(isDarkMode ? Color.white.opacity(0.2) : Color.blue.opacity(0.2))
            .frame(width: width, height: height)
            .offset(
                x: isAnimating ? endPosition.x : startPosition.x,
                y: isAnimating ? endPosition.y : startPosition.y
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
EOF

cat > Features/Common/Components/WeatherEffects/SnowEffectView.swift << 'EOF'
import SwiftUI

struct SnowEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { i in
                SnowFlake(isDarkMode: isDarkMode)
            }
        }
    }
}

struct SnowFlake: View {
    let isDarkMode: Bool
    
    @State private var isAnimating = false
    private let startPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: -20
    )
    private let endPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: UIScreen.main.bounds.height + 20
    )
    private let duration = Double.random(in: 5...10)
    private let delay = Double.random(in: 0...5)
    private let size = CGFloat.random(in: 3...8)
    private let rotation = Double.random(in: 0...360)
    
    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundColor(isDarkMode ? .white.opacity(0.7) : .white.opacity(0.9))
            .rotationEffect(.degrees(rotation))
            .offset(
                x: isAnimating ? endPosition.x : startPosition.x,
                y: isAnimating ? endPosition.y : startPosition.y
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
EOF

cat > Features/Common/Components/WeatherEffects/FogEffectView.swift << 'EOF'
import SwiftUI

struct FogEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                FogCloud(opacity: 0.2, isDarkMode: isDarkMode, index: i)
            }
        }
    }
}

struct FogCloud: View {
    let opacity: Double
    let isDarkMode: Bool
    let index: Int
    
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        isDarkMode ? Color.black.opacity(0) : Color.white.opacity(0),
                        isDarkMode ? Color.black.opacity(opacity) : Color.white.opacity(opacity),
                        isDarkMode ? Color.black.opacity(opacity) : Color.white.opacity(opacity),
                        isDarkMode ? Color.black.opacity(0) : Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 150)
            .offset(y: offsetY + CGFloat(index * 150))
            .onAppear {
                let baseOffset = UIScreen.main.bounds.height
                offsetY = baseOffset
                
                withAnimation(
                    Animation
                        .linear(duration: 100)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetY = baseOffset - 300
                }
            }
    }
}
EOF

cat > Features/Common/Components/WeatherEffects/LightningEffectView.swift << 'EOF'
import SwiftUI

struct LightningEffectView: View {
    @State private var isVisible = false
    @State private var nextFlash = Double.random(in: 3...10)
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .ignoresSafeArea()
            .opacity(isVisible ? 0.2 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if nextFlash <= 0 {
                        flashLightning()
                        nextFlash = Double.random(in: 3...10)
                    } else {
                        nextFlash -= 0.1
                    }
                }
            }
    }
    
    private func flashLightning() {
        withAnimation(.easeIn(duration: 0.1)) {
            isVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                isVisible = false
            }
            
            // Possibility of double flash
            if Bool.random() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        isVisible = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isVisible = false
                        }
                    }
                }
            }
        }
    }
}
EOF

cat > Features/Common/Components/BackgroundView.swift << 'EOF'
import SwiftUI

enum BackgroundType {
    case clear, cloudy, rainy, stormy, snowy, foggy
}

struct BackgroundView: View {
    let backgroundType: BackgroundType
    let isDarkMode: Bool
    
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            linearGradient
                .ignoresSafeArea()
                .hueRotation(.degrees(animateGradient ? 45 : 0))
                .animation(
                    Animation.easeInOut(duration: 20).repeatForever(autoreverses: true),
                    value: animateGradient
                )
            
            // Weather-specific effects
            weatherEffectsView
        }
        .onAppear {
            animateGradient = true
        }
    }
    
    private var linearGradient: LinearGradient {
        switch backgroundType {
        case .clear:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0, green: 0, blue: 0.2)] :
                    [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.8, green: 0.9, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cloudy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.9, green: 0.9, blue: 0.9)

],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rainy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.5, green: 0.5, blue: 0.7), Color(red: 0.7, green: 0.7, blue: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stormy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0, green: 0, blue: 0.1)] :
                    [Color(red: 0.3, green: 0.3, blue: 0.5), Color(red: 0.5, green: 0.5, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .snowy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.8, green: 0.8, blue: 0.9), Color(red: 1, green: 1, blue: 1)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .foggy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.1)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.9, green: 0.9, blue: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    private var weatherEffectsView: some View {
        switch backgroundType {
        case .clear:
            EmptyView()
            
        case .cloudy:
            CloudsEffectView(isDarkMode: isDarkMode)
            
        case .rainy:
            RainEffectView(isDarkMode: isDarkMode)
            
        case .stormy:
            ZStack {
                RainEffectView(isDarkMode: isDarkMode, intensity: .heavy)
                LightningEffectView()
            }
            
        case .snowy:
            SnowEffectView(isDarkMode: isDarkMode)
            
        case .foggy:
            FogEffectView(isDarkMode: isDarkMode)
        }
    }
}
EOF

# Features/Welcome/Views files
cat > Features/Welcome/Views/WelcomeView.swift << 'EOF'
import SwiftUI

struct WelcomeView: View {
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Weather App")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
            
            Image(systemName: "cloud.sun.fill")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .opacity(isAnimating ? 1 : 0)
            
            Text("Get the latest weather information for your location")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Button(action: action) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .shadow(radius: 5)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 40)
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}
EOF

# Features/Weather/ViewModels files
cat > Features/Weather/ViewModels/WeatherViewModel.swift << 'EOF'
import Foundation
import Combine
import CoreLocation
import SwiftUI

class WeatherViewModel: ObservableObject {
    // Dependencies
    private let fetchWeatherUseCase: FetchWeatherUseCaseProtocol
    private let searchCityUseCase: SearchCityUseCaseProtocol
    
    // Published properties
    @Published var currentWeather: CurrentWeather?
    @Published var hourlyForecast: [HourlyForecast] = []
    @Published var dailyForecast: [DailyForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var timezone: String?
    @Published var selectedCity: City?
    @Published var searchResults: [City] = []
    @Published var searchText = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?
    
    init(fetchWeatherUseCase: FetchWeatherUseCaseProtocol, searchCityUseCase: SearchCityUseCaseProtocol) {
        self.fetchWeatherUseCase = fetchWeatherUseCase
        self.searchCityUseCase = searchCityUseCase
        
        // Setup search debounce
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self, !searchTerm.isEmpty, searchTerm.count >= 2 else {
                    self?.searchResults = []
                    return
                }
                self.searchCity(query: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    func fetchWeather(for city: City) {
        selectedCity = city
        fetchWeather(latitude: city.coordinates.latitude, longitude: city.coordinates.longitude)
    }
    
    func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        fetchWeatherUseCase.execute(latitude: latitude, longitude: longitude)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                self?.currentWeather = response.current
                self?.hourlyForecast = Array(response.hourly.prefix(24))
                self?.dailyForecast = response.daily
                self?.timezone = response.timezone
            })
            .store(in: &cancellables)
    }
    
    func searchCity(query: String) {
        searchCityUseCase.execute(query: query) { [weak self] cities in
            self?.searchResults = cities
        }
    }
    
    func getWeatherIcon(from icon: String) -> String {
        switch icon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
    
    func getWeatherBackground(from icon: String) -> BackgroundType {
        let firstChar = icon.prefix(2)
        switch firstChar {
        case "01": return .clear
        case "02", "03", "04": return .cloudy
        case "09", "10": return .rainy
        case "11": return .stormy
        case "13": return .snowy
        case "50": return .foggy
        default: return .clear
        }
    }
}
EOF

# Features/Search/ViewModels files
cat > Features/Search/ViewModels/SearchViewModel.swift << 'EOF'
import Foundation
import Combine

class SearchViewModel: ObservableObject {
    private let searchCityUseCase: SearchCityUseCaseProtocol
    
    @Published var searchText = ""
    @Published var searchResults: [City] = []
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(searchCityUseCase: SearchCityUseCaseProtocol) {
        self.searchCityUseCase = searchCityUseCase
        
        // Setup search debounce
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self, !searchTerm.isEmpty, searchTerm.count >= 2 else {
                    self?.searchResults = []
                    return
                }
                self.searchCity(query: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    func searchCity(query: String) {
        isSearching = true
        searchCityUseCase.execute(query: query) { [weak self] cities in
            self?.searchResults = cities
            self?.isSearching = false
        }
    }
}
EOF

# Features/Weather/Views files
cat > Features/Weather/Views/ContentView.swift << 'EOF'
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherViewModel: WeatherViewModel
    @AppStorage("selectedTheme") private var isDarkMode = false
    
    init() {
        let container = AppContainer()
        _weatherViewModel = StateObject(wrappedValue: WeatherViewModel(
            fetchWeatherUseCase: container.fetchWeatherUseCase,
            searchCityUseCase: container.searchCityUseCase
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView(
                    backgroundType: weatherViewModel.currentWeather?.weather.first.map {
                        weatherViewModel.getWeatherBackground(from: $0.icon)
                    } ?? .clear,
                    isDarkMode: isDarkMode
                )
                
                VStack {
                    if weatherViewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = weatherViewModel.errorMessage {
                        ErrorView(message: errorMessage) {
                            // Retry action
                            if let city = weatherViewModel.selectedCity {
                                weatherViewModel.fetchWeather(for: city)
                            } else if let location = locationManager.location {
                                weatherViewModel.fetchWeather(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                            }
                        }
                    } else if weatherViewModel.currentWeather != nil {
                        WeatherDashboardView(
                            viewModel: weatherViewModel,
                            isDarkMode: $isDarkMode
                        )
                    } else {
                        WelcomeView {
                            locationManager.requestLocation()
                        }
                    }
                }
                .navigationTitle("Weather")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isDarkMode.toggle()
                        }) {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(isDarkMode ? .yellow : .indigo)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if let location = locationManager.location {
                                weatherViewModel.fetchWeather(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                            } else {
                                locationManager.requestLocation()
                            }
                        }) {
                            Image(systemName: "location.circle.fill")
                        }
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                weatherViewModel.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}
EOF

cat > Features/Weather/Views/WeatherDashboardView.swift << 'EOF'
import SwiftUI

struct WeatherDashboardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var isDarkMode: Bool
    @State private var showingSearchSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current weather card
                if let current = viewModel.currentWeather, let condition = current.weather.first {
                    CurrentWeatherCard(
                        current: current,
                        condition: condition,
                        cityName: viewModel.selectedCity?.name ?? "Current Location",
                        isDarkMode: isDarkMode,
                        viewModel: viewModel
                    )
                    .transition(.scale)
                }
                
                // Hourly forecast
                HourlyForecastView(hourlyData: viewModel.hourlyForecast, viewModel: viewModel)
                    .transition(.move(edge: .trailing))
                
                // Daily forecast
                DailyForecastView(dailyData: viewModel.dailyForecast, viewModel: viewModel)
                    .transition(.move(edge: .bottom))
                
                // Weather details
                if let current = viewModel.currentWeather {
                    WeatherDetailsView(current: current, isDarkMode: isDarkMode)
                        .transition(.scale)
                }
            }
            .padding()
        }
        .refreshable {
            if let city = viewModel.selectedCity {
                viewModel.fetchWeather(for: city)
            } else if let location = LocationManager().location {
                viewModel.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(weatherViewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSearchSheet = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
EOF

cat > Features/Weather/Views/CurrentWeatherCard.swift << 'EOF'
import SwiftUI

struct CurrentWeatherCard: View {
    let current: CurrentWeather
    let condition: WeatherCondition
    let cityName: String
    let isDarkMode: Bool
    let viewModel: WeatherViewModel
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(cityName)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .center, spacing: 20) {
                Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 10)
                            .repeatForever(autoreverses: false)
                            .delay(1),
                        value: isAnimating
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(Int(current.temp))°C")
                        .font(.system(size: 50, weight: .bold))
                    
                    Text(condition.description.capitalized)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
            
            HStack(spacing: 30) {
                WeatherDataPill(
                    icon: "thermometer",
                    title: "Feels Like",
                    value: "\(Int(current.feelsLike))°C",
                    isDarkMode: isDarkMode
                )
                
                WeatherDataPill(
                    icon: "wind",
                    title: "Wind",
                    value: "\(Int(current.windSpeed)) m/s",
                    isDarkMode: isDarkMode
                )
                
                WeatherDataPill(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(current.humidity)%",
                    isDarkMode: isDarkMode
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? 
                      Color(UIColor.systemGray6).opacity(0.8) :
                      Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            isAnimating = true
        }
    }
}
EOF

cat > Features/Weather/Views/HourlyForecastView.swift << 'EOF'
import SwiftUI

struct HourlyForecastView: View {
    let hourlyData: [HourlyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourlyData) { hour in
                        if let condition = hour.weather.first {
                            HourlyForecastCell(
                                hour: hour,
                                iconName: viewModel.getWeatherIcon(from: condition.icon)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
}

struct HourlyForecastCell: View {
    let hour: HourlyForecast
    let iconName: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(DateFormatters.hourFormatter.string(from: hour.date))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 22))
            
            Text("\(Int(hour.temp))°")
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(height: 100)
    }
}
EOF

cat > Features/Weather/Views/DailyForecastView.swift << 'EOF'
import SwiftUI

struct DailyForecastView: View {
    let dailyData: [DailyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.leading)
            
            ForEach(dailyData) { day in
                if let condition = day.weather.first {
                    DailyForecastRow(
                        day: day,
                        iconName: viewModel.getWeatherIcon(from: condition.icon)
                    )
                    
                    if day.id != dailyData.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
}

struct DailyForecastRow: View {
    let day: DailyForecast
    let iconName: String
    
    var body: some View {
        HStack {
            Text(DateFormatters.dayFormatter.string(from: day.date))
                .font(.system(size: 16))
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 22))
            
            Spacer()
            
            Text("☔️ \(Int(day.pop * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            HStack(spacing: 5) {
                Text("\(Int(day.temp.min))°")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("\(Int(day.temp.max))°")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}
EOF

cat > Features/Weather/Views/WeatherDetailsView.swift << 'EOF'
import SwiftUI

struct WeatherDetailsView: View {
    let current: CurrentWeather
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weather Details")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                WeatherDetailCell(
                    icon: "sun.max.fill",
                    title: "UV Index",
                    value: getUVIndexDescription(current.uvi),
                    isDarkMode: isDarkMode
                )
                
                WeatherDetailCell(
                    icon: "eye.fill",
                    title: "Visibility",
                    value: "\(current.visibility / 1000) km",
                    isDarkMode: isDarkMode
                )
                
                WeatherDetailCell(
                    icon: "gauge",
                    title: "Pressure",
                    value: "\(current.pressure) hPa",
                    isDarkMode: isDarkMode
                )
                
                WeatherDetailCell(
                    icon: "humidity.fill",
                    title: "Humidity",
                    value: "\(current.humidity)%",
                    isDarkMode: isDarkMode
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
    
    private func getUVIndexDescription(_ uvi: Double) -> String {
        switch uvi {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }
}

struct WeatherDetailCell: View {
    let icon: String
    let title: String
    let value: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .renderingMode(.original)
                .font(.system(size: 22))
                .foregroundColor(isDarkMode ? .white : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
EOF

# Features/Search/Views files
cat > Features/Search/Views/SearchView.swift << 'EOF'
import SwiftUI

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a city", text: $weatherViewModel.searchText)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                List(weatherViewModel.searchResults) { city in
                    Button(action: {
                        weatherViewModel.fetchWeather(for: city)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(city.fullName)
                    }
                }
                .listStyle(PlainListStyle())
                
                if weatherViewModel.searchResults.isEmpty && !weatherViewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                }
            }
            .navigationTitle("Search City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
EOF

# Config files
cat > Config/AppConfiguration.swift << 'EOF'
import Foundation

enum AppConfiguration {
    // MARK: - API Keys
    
    #if DEBUG
    static let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_OPENWEATHER_API_KEY"
    #else
    static let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_PRODUCTION_API_KEY"
    #endif
    
    // MARK: - API URLs
    
    static let baseURL = "https://api.openweathermap.org/data/3.0"
    static let geoURL = "https://api.openweathermap.org/geo/1.0"
    
    // MARK: - App Configuration
    
    static let defaultTempUnit = "metric" // metric or imperial
    static let cacheDuration: TimeInterval = 60 * 30 // 30 minutes
}
EOF

cat > Config/Development.xcconfig << 'EOF'
//
//  Development.xcconfig
//  WeatherApp
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

OPENWEATHER_API_KEY = YOUR_DEVELOPMENT_API_KEY
EOF

cat > Config/Production.xcconfig << 'EOF'
//
//  Production.xcconfig
//  WeatherApp
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

OPENWEATHER_API_KEY = YOUR_PRODUCTION_API_KEY
EOF

# Create Info.plist file with location permissions
cat > Resources/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to provide accurate weather information for your current area.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

echo -e "${GREEN}All files have been created successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Open Xcode and create a new SwiftUI project named 'WeatherApp'"
echo "2. Replace the auto-generated files with the files created by this script"
echo "3. Replace 'YOUR_OPENWEATHER_API_KEY' with your actual API key from OpenWeather"
echo "4. Build and run the application"
echo ""
echo -e "${GREEN}Your modern weather app with SwiftUI is ready to be built!${NC}"

# Make the script executable
chmod +x setup-weather-app.sh

cd ..
echo -e "${BLUE}Script setup complete!${NC}"

