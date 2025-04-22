import SwiftUI

struct WeatherDashboardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSearchSheet = false
    @State private var showingSettingsSheet = false
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    private let tabs = ["Today", "Hourly", "Daily", "Details"]
    
    var body: some View {
        VStack(spacing: 0) {
            // City name header
            headerView
            
            // Current weather card
            if let current = viewModel.currentWeather, let condition = current.weather.first {
                weatherContentView(current: current, condition: condition)
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(weatherViewModel: viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .environmentObject(themeManager)
        }
        .refreshable {
            isRefreshing = true
            refreshWeatherData()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(viewModel.selectedCity?.name ?? "Current Location")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let country = viewModel.selectedCity?.country, !country.isEmpty {
                        Text(country)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button {
                    showingSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                        .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                        .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
            }
        }
        .padding()
        .background(headerBackground)
        .foregroundColor(.white)
    }
    
    // MARK: - Background View for Header
    private var headerBackground: some View {
        ZStack {
            if let current = viewModel.currentWeather, let condition = current.weather.first {
                Rectangle()
                    .fill(LinearGradient(
                        colors: gradientColors(for: condition.icon),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
    
    // MARK: - Weather Content View
    private func weatherContentView(current: CurrentWeather, condition: WeatherCondition) -> some View {
        VStack(spacing: 0) {
            // Current weather summary
            currentWeatherSummary(current: current, condition: condition)
            
            // Tab selector
            tabSelectorView
            
            // Tab content
            tabContentView(current: current)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Current Weather Summary
    private func currentWeatherSummary(current: CurrentWeather, condition: WeatherCondition) -> some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .center) {
                Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                    .padding(.bottom, 5)
                
                Text(condition.description.capitalized)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Int(current.temp))°")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(themeManager.accentColor)
                
                HStack(spacing: 15) {
                    Label("Feels like \(Int(current.feelsLike))°", systemImage: "thermometer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    private var tabSelectorView: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: selectedTab == index ? .bold : .regular))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(tabButtonBackground(for: index))
                        .foregroundColor(selectedTab == index ? .white : .primary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Button Background
    private func tabButtonBackground(for index: Int) -> some View {
        Group {
            if selectedTab == index {
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.accentColor)
                    .shadow(color: themeManager.accentColor.opacity(0.3), radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
            }
        }
    }
    
    // MARK: - Tab Content View
    private func tabContentView(current: CurrentWeather) -> some View {
        TabView(selection: $selectedTab) {
            // Today tab
            todayTabView(current: current)
                .tag(0)
            
            // Hourly tab
            hourlyTabView
                .tag(1)
            
            // Daily tab
            dailyTabView
                .tag(2)
            
            // Details tab
            detailsTabView(current: current)
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    // MARK: - Today Tab
    private func todayTabView(current: CurrentWeather) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weather highlights
                WeatherHighlightsView(current: current, themeManager: themeManager)
                
                // Next 24 hours
                HourlyForecastView(hourlyData: viewModel.hourlyForecast.prefix(8).map { $0 }, viewModel: viewModel)
                    .transition(.move(edge: .trailing))
            }
            .padding()
        }
    }
    
    // MARK: - Hourly Tab
    private var hourlyTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                DetailedHourlyForecastView(hourlyData: viewModel.hourlyForecast, viewModel: viewModel)
            }
            .padding()
        }
    }
    
    // MARK: - Daily Tab
    private var dailyTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                DailyForecastView(dailyData: viewModel.dailyForecast, viewModel: viewModel)
                    .transition(.move(edge: .bottom))
            }
            .padding()
        }
    }
    
    // MARK: - Details Tab
    private func detailsTabView(current: CurrentWeather) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                WeatherDetailsView(current: current, isDarkMode: themeManager.isDarkMode)
                    .transition(.scale)
                
                // Additional info
                WeatherInfoCardView(viewModel: viewModel)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    private func refreshWeatherData() {
        if let city = viewModel.selectedCity {
            viewModel.fetchWeather(for: city)
        } else if let location = LocationManager().location {
            viewModel.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        // Add a small delay to make the refresh indicator visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
    
    private func gradientColors(for icon: String) -> [Color] {
        let backgroundType = viewModel.getWeatherBackground(from: icon)
        let isDarkMode = themeManager.isDarkMode
        
        switch backgroundType {
        case .clear:
            return isDarkMode ?
                [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0, green: 0, blue: 0.2)] :
                [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.8)]
        case .cloudy:
            return isDarkMode ?
                [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                [Color(red: 0.7, green: 0.7, blue: 0.8), Color(red: 0.5, green: 0.5, blue: 0.6)]
        case .rainy:
            return isDarkMode ?
                [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                [Color(red: 0.4, green: 0.4, blue: 0.6), Color(red: 0.2, green: 0.2, blue: 0.4)]
        case .stormy:
            return isDarkMode ?
                [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0, green: 0, blue: 0.1)] :
                [Color(red: 0.3, green: 0.3, blue: 0.4), Color(red: 0.1, green: 0.1, blue: 0.2)]
        case .snowy:
            return isDarkMode ?
                [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                [Color(red: 0.7, green: 0.7, blue: 0.8), Color(red: 0.5, green: 0.5, blue: 0.6)]
        case .foggy:
            return isDarkMode ?
                [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.1)] :
                [Color(red: 0.6, green: 0.6, blue: 0.6), Color(red: 0.4, green: 0.4, blue: 0.4)]
        }
    }
}

// Keep the existing components unchanged below
struct WeatherHighlightsView: View {
    let current: CurrentWeather
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Highlights")
                .font(.headline)
                .padding(.leading, 8)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                HighlightCard(
                    icon: "wind",
                    title: "Wind",
                    value: "\(Int(current.windSpeed)) m/s",
                    accentColor: themeManager.accentColor
                )
                
                HighlightCard(
                    icon: "humidity.fill",
                    title: "Humidity",
                    value: "\(current.humidity)%",
                    accentColor: themeManager.accentColor
                )
                
                HighlightCard(
                    icon: "sun.max.fill",
                    title: "UV Index",
                    value: getUVIndexDescription(current.uvi),
                    accentColor: themeManager.accentColor
                )
                
                HighlightCard(
                    icon: "gauge",
                    title: "Pressure",
                    value: "\(current.pressure) hPa",
                    accentColor: themeManager.accentColor
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
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

struct HighlightCard: View {
    let icon: String
    let title: String
    let value: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}

struct WeatherInfoCardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Info")
                .font(.headline)
                .padding(.leading, 8)
            
            VStack(alignment: .leading, spacing: 15) {
                if let city = viewModel.selectedCity {
                    InfoRow(title: "Location", value: "\(city.name), \(city.country)")
                }
                
                if let timezone = viewModel.timezone {
                    InfoRow(title: "Timezone", value: timezone)
                }
                
                InfoRow(title: "Last Updated", value: Date(), isDate: true)
                
                InfoRow(title: "Data Source", value: "OpenWeatherMap")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

struct InfoRow: View {
    let title: String
    let value: Any
    var isDate: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            if isDate, let date = value as? Date {
                Text(date, style: .relative)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            } else {
                Text("\(value as? String ?? "")")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct DetailedHourlyForecastView: View {
    let hourlyData: [HourlyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("48-Hour Forecast")
                .font(.headline)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                ForEach(hourlyData.prefix(48)) { hour in
                    if let condition = hour.weather.first {
                        HourlyDetailRow(
                            hour: hour,
                            iconName: viewModel.getWeatherIcon(from: condition.icon),
                            description: condition.description.capitalized
                        )
                        
                        if hour.id != hourlyData.prefix(48).last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

struct HourlyDetailRow: View {
    let hour: HourlyForecast
    let iconName: String
    let description: String
    
    var body: some View {
        HStack {
            Text(hour.date, style: .time)
                .font(.system(size: 16))
                .frame(width: 60, alignment: .leading)
            
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 22))
                .frame(width: 40)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(hour.temp))°")
                .font(.system(size: 18, weight: .bold))
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
