import SwiftUI

struct WeatherDashboardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSearchSheet = false
    @State private var showingSettingsSheet = false
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 180
    @State private var iconScale: CGFloat = 1.0
    
    private let tabs = ["Today", "Hourly", "Daily", "Details"]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            if let current = viewModel.currentWeather, let condition = current.weather.first {
                backgroundGradient(for: condition.icon)
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer to account for fixed header
                    Spacer()
                        .frame(height: headerHeight)
                    
                    // Current weather summary - moves under header when scrolling
                    if let current = viewModel.currentWeather, let condition = current.weather.first {
                        currentWeatherView(current: current, condition: condition)
                            .padding(.top, 20)
                    }
                    
                    // Content tabs
                    VStack(spacing: 0) {
                        // Tab selector
                        tabSelectorView
                            .padding(.top, 20)
                        
                        // Tab content
                        if let current = viewModel.currentWeather {
                            tabContentView(current: current)
                                .padding(.top, 10)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(UIColor.systemGroupedBackground))
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .offset(y: -25) // Overlap with current weather view
                }
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                         value: geo.frame(in: .named("scrollView")).minY)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    
                    // Scale icon based on scroll
                    if value < 0 {
                        iconScale = max(0.6, 1.0 + (value / 500))
                    } else {
                        iconScale = min(1.3, 1.0 + (value / 200))
                    }
                }
            }
            .coordinateSpace(name: "scrollView")
            .refreshable {
                isRefreshing = true
                refreshWeatherData()
            }
            
            // Fixed header with city name and weather icon
            cityHeaderView
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(weatherViewModel: viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .environmentObject(themeManager)
        }
    }
    
    // MARK: - City Header View
    private var cityHeaderView: some View {
        VStack(spacing: 0) {
            // Status bar background
            Color.clear
                .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                .background(
                    Color.clear
                        .background(
                            Material.thin
                        )
                )
            
            // Main header content
            ZStack {
                // Blurred background
                Material.thin
                
                HStack {
                    // City name and country
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(viewModel.selectedCity?.name ?? "Current Location")
                                .font(.system(size: 28, weight: .bold))
                                .lineLimit(1)
                            
                            if let country = viewModel.selectedCity?.country, !country.isEmpty {
                                Text(country)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Current temperature
                        if let current = viewModel.currentWeather {
                            Text("\(Int(current.temp))°")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Weather icon
                    if let current = viewModel.currentWeather, let condition = current.weather.first {
                        Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .scaleEffect(iconScale)
                            .animation(.spring(response: 0.3), value: iconScale)
                    }
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button {
                            showingSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                                .shadow(color: Color.black.opacity(0.05), radius: 5)
                        }
                        
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                                .shadow(color: Color.black.opacity(0.05), radius: 5)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .frame(height: headerHeight - (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0))
        }
        .shadow(color: Color.black.opacity(scrollOffset < -10 ? 0.1 : 0), radius: 5)
        .animation(.easeInOut, value: scrollOffset < -10)
    }
    
    // MARK: - Current Weather View
    private func currentWeatherView(current: CurrentWeather, condition: WeatherCondition) -> some View {
        VStack(spacing: 15) {
            // Weather description
            Text(condition.description.capitalized)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            // Feels like temperature
            Text("Feels like \(Int(current.feelsLike))°")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .shadow(radius: 1)
            
            // Weather highlights - horizontal grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                weatherDataTile(icon: "wind", title: "Wind", value: "\(Int(current.windSpeed)) m/s")
                weatherDataTile(icon: "humidity.fill", title: "Humidity", value: "\(current.humidity)%")
                weatherDataTile(icon: "gauge", title: "Pressure", value: "\(current.pressure) hPa")
                weatherDataTile(icon: "sun.max.fill", title: "UV Index", value: getUVIndexDescription(current.uvi))
                weatherDataTile(icon: "eye.fill", title: "Visibility", value: formatVisibility(current.visibility))
                weatherDataTile(icon: "thermometer", title: "Range", value: "\(getDailyRange())°")
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    // Weather data tile for current weather grid
    private func weatherDataTile(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .shadow(radius: 1)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.2))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
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
                        .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(tabButtonBackground(for: index))
                        .foregroundColor(selectedTab == index ? .white : .primary)
                        .cornerRadius(20)
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
        .frame(minHeight: 600)
    }
    
    // MARK: - Today Tab
    private func todayTabView(current: CurrentWeather) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hourly forecast for next 24 hours
                VStack(alignment: .leading, spacing: 10) {
                    Text("Next 24 Hours")
                        .font(.headline)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.hourlyForecast.prefix(24)) { hour in
                                if let condition = hour.weather.first {
                                    enhancedHourlyCell(hour: hour, iconName: viewModel.getWeatherIcon(from: condition.icon))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // Summary for today
                if !viewModel.dailyForecast.isEmpty, let today = viewModel.dailyForecast.first {
                    todaySummaryCard(daily: today)
                }
                
                // Last updated info
                if let lastUpdated = viewModel.lastUpdated {
                    HStack {
                        Text("Last updated:")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(lastUpdated, style: .relative)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
    
    // Enhanced hourly cell with better styling
    private func enhancedHourlyCell(hour: HourlyForecast, iconName: String) -> some View {
        VStack(spacing: 12) {
            // Time
            Text(formatHour(hour.date))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            // Weather icon
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 24))
                .frame(height: 30)
            
            // Temperature
            Text("\(Int(hour.temp))°")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.accentColor)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // Today's summary card
    private func todaySummaryCard(daily: DailyForecast) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Summary")
                .font(.headline)
                .padding(.leading)
            
            HStack(alignment: .top, spacing: 20) {
                if let condition = daily.weather.first {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                            .renderingMode(.original)
                            .font(.system(size: 40))
                        
                        Text(condition.description.capitalized)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("High:")
                            .foregroundColor(.secondary)
                        Text("\(Int(daily.temp.max))°")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Low:")
                            .foregroundColor(.secondary)
                        Text("\(Int(daily.temp.min))°")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Precipitation:")
                            .foregroundColor(.secondary)
                        Text("\(Int(daily.pop * 100))%")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if let timezone = viewModel.timezone {
                            Text("Timezone:")
                                .foregroundColor(.secondary)
                            Text(timezone)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                    }
                    
                    if let current = viewModel.currentWeather {
                        HStack {
                            Text("UV Index:")
                                .foregroundColor(.secondary)
                            Text(getUVIndexDescription(current.uvi))
                                .fontWeight(.semibold)
                                .foregroundColor(getUVIndexColor(current.uvi))
                                
                            Spacer()
                            
                            Text("Visibility:")
                                .foregroundColor(.secondary)
                            Text(formatVisibility(current.visibility))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Hourly Tab
    private var hourlyTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                enhancedHourlyForecastView(hourlyData: viewModel.hourlyForecast)
                    .transition(.move(edge: .trailing))
            }
            .padding()
        }
    }
    
    // Enhanced hourly forecast view with grouping by day
    private func enhancedHourlyForecastView(hourlyData: [HourlyForecast]) -> some View {
        let groupedByDay = Dictionary(grouping: hourlyData) { hourly -> String in
            let date = hourly.date
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
        
        return VStack(spacing: 20) {
            ForEach(groupedByDay.keys.sorted(), id: \.self) { day in
                if let hoursForDay = groupedByDay[day] {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(day)
                            .font(.headline)
                            .padding(.leading)
                        
                        ForEach(hoursForDay) { hour in
                            if let condition = hour.weather.first {
                                HStack {
                                    // Time
                                    Text(formatHourOnly(hour.date))
                                        .font(.system(size: 16))
                                        .frame(width: 50, alignment: .leading)
                                    
                                    // Icon
                                    Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                                        .renderingMode(.original)
                                        .font(.system(size: 22))
                                        .frame(width: 40)
                                    
                                    // Description
                                    Text(condition.description.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // Temperature
                                    Text("\(Int(hour.temp))°")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(themeManager.accentColor)
                                        .frame(width: 50, alignment: .trailing)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
            }
        }
    }
    
    // MARK: - Daily Tab
    private var dailyTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                enhancedDailyForecastView(dailyData: viewModel.dailyForecast)
                    .transition(.move(edge: .bottom))
            }
            .padding()
        }
    }
    
    // Enhanced daily forecast with more details
    private func enhancedDailyForecastView(dailyData: [DailyForecast]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.leading)
            
            ForEach(dailyData) { day in
                if let condition = day.weather.first {
                    VStack(spacing: 10) {
                        // Day and date
                        HStack {
                            Text(formatDayWithDate(day.date))
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("☔️ \(Int(day.pop * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .center) {
                            // Weather icon and condition
                            HStack {
                                Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                                    .renderingMode(.original)
                                    .font(.system(size: 30))
                                
                                Text(condition.description.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Temperature range with bar
                            VStack(alignment: .trailing, spacing: 5) {
                                HStack(spacing: 10) {
                                    Text("\(Int(day.temp.min))°")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    tempRangeBar(min: day.temp.min, max: day.temp.max,
                                              dailyData: dailyData)
                                    
                                    Text("\(Int(day.temp.max))°")
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: 30, alignment: .leading)
                                }
                                
                                Text("Feels like \(Int(day.temp.day))° during day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.03), radius: 3)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // Temperature range visualization bar
    private func tempRangeBar(min: Double, max: Double, dailyData: [DailyForecast]) -> some View {
        // Find global min and max across all days for proper scaling
        let allTemps = dailyData.flatMap { [$0.temp.min, $0.temp.max] }
        let globalMin = allTemps.min() ?? min
        let globalMax = allTemps.max() ?? max
        let range = globalMax - globalMin
        
        // Calculate normalized positions (0.0 - 1.0)
        let normalizedMin = range > 0 ? (min - globalMin) / range : 0
        let normalizedMax = range > 0 ? (max - globalMin) / range : 1
        
        return ZStack(alignment: .leading) {
            // Background bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 8)
            
            // Colored temperature range
            Capsule()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, themeManager.accentColor, .orange, .red]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 100 * (normalizedMax - normalizedMin), height: 8)
                .offset(x: 100 * normalizedMin)
        }
    }
    
    // MARK: - Details Tab
    private func detailsTabView(current: CurrentWeather) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weather details cards
                detailedWeatherView(current: current)
                
                // Additional info about location and data source
                locationInfoView
            }
            .padding()
        }
    }
    
    // MARK: - Enhanced Weather Details
    private func detailedWeatherView(current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weather Details")
                .font(.headline)
                .padding(.leading)
            
            // UV Index card with visualization
            uvIndexCard(uvi: current.uvi)
            
            // Wind card with direction info
            windCard(speed: current.windSpeed)
            
            // Humidity card with visualization
            humidityCard(humidity: current.humidity)
            
            // Pressure card
            pressureCard(pressure: current.pressure)
            
            // Visibility card
            visibilityCard(visibility: current.visibility)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    // UV Index detail card
    private func uvIndexCard(uvi: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                    
                    Text("UV Index")
                        .font(.headline)
                }
                
                Text("\(Int(uvi))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(getUVIndexColor(uvi))
                
                Text(getUVIndexDescription(uvi))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // UV Index visualization
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(getUVIndexColor(uvi))
                        .frame(width: min(uvi / 12.0, 1.0) * 200, height: 10)
                }
                .padding(.top, 5)
            }
            
            Spacer()
            
            // UV Protection recommendation
            VStack(alignment: .trailing, spacing: 5) {
                if uvi > 3 {
                    Label("Sunscreen", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                if uvi > 5 {
                    Label("Hat", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                if uvi > 7 {
                    Label("Sunglasses", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                if uvi > 9 {
                    Label("Stay indoors", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
    
    // Wind detail card with direction
    private func windCard(speed: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "wind")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                    
                    Text("Wind")
                        .font(.headline)
                }
                
                Text("\(Int(speed)) m/s")
                    .font(.system(size: 28, weight: .bold))
                
                Text(getWindDescription(speed))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Wind direction indicator (simplified, would use actual wind direction in real app)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 5)
                    .frame(width: 80, height: 80)
                
                // Wind direction arrow (example)
                Image(systemName: "arrow.up")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(45)) // Example direction
                
                // Cardinal direction label (example)
                Text("NE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .offset(y: 40)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
    
    // Humidity detail card
    private func humidityCard(humidity: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "humidity.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.cyan)
                    
                    Text("Humidity")
                        .font(.headline)
                }
                
                Text("\(humidity)%")
                    .font(.system(size: 28, weight: .bold))
                
                Text(getHumidityDescription(humidity))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Humidity visualization
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: CGFloat(humidity) / 100.0 * 200, height: 10)
                }
                .padding(.top, 5)
            }
            
            Spacer()
            
            // Humidity level icon
            Image(systemName: humidity > 70 ? "drop.fill" : (humidity > 40 ? "drop.degreesign" : "drop"))
                .font(.system(size: 40))
                .foregroundColor(.cyan)
                .opacity(Double(humidity) / 100.0 + 0.3)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
    
    // Pressure detail card
    private func pressureCard(pressure: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "gauge")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                    
                    Text("Pressure")
                        .font(.headline)
                }
                
                Text("\(pressure) hPa")
                    .font(.system(size: 28, weight: .bold))
                
                Text(getPressureDescription(pressure))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Pressure gauge visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 5)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: getPressureGaugeValue(pressure))
                    .stroke(Color.orange, lineWidth: 5)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text(pressure > 1013 ? "High" : (pressure < 990 ? "Low" : "Normal"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
    
    // Visibility detail card
    private func visibilityCard(visibility: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                    
                    Text("Visibility")
                        .font(.headline)
                }
                
                Text(formatVisibility(visibility))
                    .font(.system(size: 28, weight: .bold))
                
                Text(getVisibilityDescription(visibility))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Visibility visualization
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.7), .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: min(CGFloat(visibility) / 10000.0, 1.0) * 200, height: 10)
                }
                .padding(.top, 5)
            }
            
            Spacer()
            
            // Visibility icon
            Image(systemName: visibility > 8000 ? "sun.haze.fill" : (visibility > 4000 ? "cloud.fog.fill" : "fog.fill"))
                .font(.system(size: 40))
                .foregroundColor(.purple.opacity(0.7))
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
    
    // MARK: - Location Info View
    private var locationInfoView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Location Information")
                .font(.headline)
                .padding(.leading)
            
            VStack(spacing: 15) {
                if let city = viewModel.selectedCity {
                    infoRow(icon: "mappin.circle.fill", title: "Location", value: "\(city.name), \(city.country)")
                }
                
                if let timezone = viewModel.timezone {
                    infoRow(icon: "globe", title: "Timezone", value: timezone)
                }
                
                infoRow(icon: "arrow.counterclockwise", title: "Last Updated", value: viewModel.lastUpdated ?? Date(), isDate: true)
                
                infoRow(icon: "cloud", title: "Data Source", value: "OpenWeatherMap API")
                
                Button(action: {
                    refreshWeatherData()
                }) {
                    Label("Refresh Weather Data", systemImage: "arrow.clockwise")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.accentColor)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.03), radius: 3)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
    
    private func infoRow(icon: String, title: String, value: Any, isDate: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isDate, let date = value as? Date {
                Text(date, style: .relative)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.trailing)
            } else {
                Text("\(value as? String ?? "")")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Background gradient based on weather condition
    private func backgroundGradient(for icon: String) -> LinearGradient {
        let backgroundType = viewModel.getWeatherBackground(from: icon)
        let isDarkMode = themeManager.isDarkMode
        
        switch backgroundType {
        case .clear:
            return LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0, green: 0, blue: 0.2)] :
                    [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cloudy:
            return LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.8), Color(red: 0.5, green: 0.5, blue: 0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rainy:
            return LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.4, green: 0.4, blue: 0.6), Color(red: 0.2, green: 0.2, blue: 0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stormy:
            return LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0, green: 0, blue: 0.1)] :
                    [Color(red: 0.3, green: 0.3, blue: 0.4), Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .snowy:
            return LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.8), Color(red: 0.5, green: 0.5, blue: 0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .foggy:
            return LinearGradient(
                colors: isDarkMode ?
                [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.1)] :
                                    [Color(red: 0.6, green: 0.6, blue: 0.6), Color(red: 0.4, green: 0.4, blue: 0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                    
                    private func refreshWeatherData() {
                        if let city = viewModel.selectedCity {
                            viewModel.fetchWeather(for: city)
                        } else {
                            viewModel.fetchCurrentLocationWeather()
                        }
                        
                        // Add a small delay to make the refresh indicator visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isRefreshing = false
                        }
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
                    
                    private func getUVIndexColor(_ uvi: Double) -> Color {
                        switch uvi {
                        case 0..<3: return .green
                        case 3..<6: return .yellow
                        case 6..<8: return .orange
                        case 8..<11: return .red
                        default: return .purple
                        }
                    }
                    
                    private func getWindDescription(_ speed: Double) -> String {
                        switch speed {
                        case 0..<0.5: return "Calm"
                        case 0.5..<4: return "Light breeze"
                        case 4..<8: return "Moderate breeze"
                        case 8..<14: return "Strong breeze"
                        case 14..<20: return "Moderate gale"
                        case 20..<30: return "Strong gale"
                        default: return "Storm"
                        }
                    }
                    
                    private func getHumidityDescription(_ humidity: Int) -> String {
                        switch humidity {
                        case 0..<30: return "Low (Dry)"
                        case 30..<60: return "Moderate"
                        case 60..<80: return "High"
                        default: return "Very High"
                        }
                    }
                    
                    private func getPressureDescription(_ pressure: Int) -> String {
                        switch pressure {
                        case 0..<980: return "Very Low"
                        case 980..<1000: return "Low"
                        case 1000..<1013: return "Slightly Low"
                        case 1013..<1020: return "Normal"
                        case 1020..<1040: return "High"
                        default: return "Very High"
                        }
                    }
                    
                    private func getPressureGaugeValue(_ pressure: Int) -> Double {
                        // Map pressure to a 0.0-1.0 scale for gauge
                        // Typical range: 970-1040 hPa
                        let minPressure: Double = 970
                        let maxPressure: Double = 1040
                        let normalizedPressure = min(max(Double(pressure) - minPressure, 0) / (maxPressure - minPressure), 1)
                        return normalizedPressure
                    }
                    
                    private func getVisibilityDescription(_ visibility: Int) -> String {
                        let km = Double(visibility) / 1000.0
                        switch km {
                        case 0..<1: return "Very Poor"
                        case 1..<4: return "Poor"
                        case 4..<8: return "Moderate"
                        case 8..<10: return "Good"
                        default: return "Excellent"
                        }
                    }
                    
                    private func formatVisibility(_ visibility: Int) -> String {
                        let kilometers = Double(visibility) / 1000.0
                        return String(format: "%.1f km", kilometers)
                    }
                    
                    private func formatHour(_ date: Date) -> String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "ha"
                        return formatter.string(from: date)
                    }
                    
                    private func formatHourOnly(_ date: Date) -> String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        return formatter.string(from: date)
                    }
                    
                    private func formatDayWithDate(_ date: Date) -> String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE, MMM d"
                        return formatter.string(from: date)
                    }
                    
                    private func getDailyRange() -> String {
                        if let daily = viewModel.dailyForecast.first {
                            return "\(Int(daily.temp.min))-\(Int(daily.temp.max))"
                        }
                        return ""
                    }
                }

                // Preference key to track scroll offset
                struct ScrollOffsetPreferenceKey: PreferenceKey {
                    static var defaultValue: CGFloat = 0
                    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
                        value = nextValue()
                    }
                }
