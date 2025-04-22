
import SwiftUI

struct WeatherDashboardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSearchSheet = false
    @State private var showingSettingsSheet = false
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 130
    @State private var iconScale: CGFloat = 1.0
    
    private let tabs = ["Today", "Hourly", "Week", "Details"]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Dynamic weather background with parallax effect
            if let current = viewModel.currentWeather, let condition = current.weather.first {
                weatherBackground(for: condition.icon)
                    .ignoresSafeArea()
                    .offset(y: min(0, scrollOffset / 3)) // Parallax effect
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer to account for fixed header
                    Spacer().frame(height: headerHeight + 20)
                    
                    // Current weather display
                    if let current = viewModel.currentWeather, let condition = current.weather.first {
                        currentWeatherSummary(current: current, condition: condition)
                            .padding(.top, 10)
                    }
                    
                    // Content tabs in frosted glass card
                    VStack(spacing: 0) {
                        // Tab selector bar
                        tabSelectorView
                            .padding(.top, 15)
                        
                        // Tab content area
                        if let current = viewModel.currentWeather {
                            tabContentView(current: current)
                                .padding(.top, 5)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(UIColor.systemBackground).opacity(0.85))
                            .shadow(color: Color.black.opacity(0.1), radius: 15)
                            .blur(radius: 0.5)
                    )
                    .offset(y: -20)
                }
                .background(GeometryReader { geo in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                         value: geo.frame(in: .named("scrollView")).minY)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    
                    // Dynamic icon animation based on scroll
                    if value < 0 {
                        iconScale = max(0.8, 1.0 + (value / 400))
                    } else {
                        iconScale = min(1.5, 1.0 + (value / 150))
                    }
                }
            }
            .coordinateSpace(name: "scrollView")
            .refreshable {
                isRefreshing = true
                refreshWeatherData()
            }
            
            // Floating header with city name and weather
            cityHeader
                .animation(.interpolatingSpring(stiffness: 100, damping: 15), value: scrollOffset)
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
    
    // MARK: - UI Components
    
    // Animated weather background based on condition
    private func weatherBackground(for icon: String) -> some View {
        let backgroundType = viewModel.getWeatherBackground(from: icon)
        let isDarkMode = themeManager.isDarkMode
        
        switch backgroundType {
        case .clear:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0, green: 0, blue: 0.2)] :
                            [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Sun/moon and subtle clouds in clear weather
                    if !isDarkMode {
                        Circle()
                            .fill(Color.yellow.opacity(0.7))
                            .frame(width: 100, height: 100)
                            .blur(radius: 15)
                            .offset(x: 120, y: -100)
                            .scaleEffect(1 + (scrollOffset > 0 ? scrollOffset/500 : 0))
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 70, height: 70)
                            .blur(radius: 10)
                            .offset(x: 130, y: -90)
                            .scaleEffect(1 + (scrollOffset > 0 ? scrollOffset/600 : 0))
                    }
                    
                    // Subtle cloud elements
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(0.1 + Double(i) * 0.05))
                            .frame(width: 80 + CGFloat(i * 20), height: 50 + CGFloat(i * 10))
                            .blur(radius: 15)
                            .offset(x: -120 + CGFloat(i * 40), y: -100 + CGFloat(i * 50))
                    }
                }
            )
            
        case .cloudy:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                            [Color(red: 0.7, green: 0.8, blue: 0.9), Color(red: 0.5, green: 0.6, blue: 0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Cloud elements
                    ForEach(0..<5) { i in
                        CloudShape()
                            .fill(Color.white.opacity(0.2 + Double(i % 3) * 0.1))
                            .frame(width: 120 + CGFloat(i * 15), height: 60 + CGFloat(i * 5))
                            .offset(x: -150 + CGFloat(i * 70), y: -150 + CGFloat(i * 60))
                            .offset(y: scrollOffset > 0 ? scrollOffset/8 : 0)
                    }
                }
            )
            
        case .rainy:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.1)] :
                            [Color(red: 0.4, green: 0.4, blue: 0.5), Color(red: 0.3, green: 0.3, blue: 0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Animated rain effect
                    ForEach(0..<20) { i in
                        RainDrop()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 2, height: 15 + CGFloat.random(in: 0...10))
                            .offset(x: -180 + CGFloat(i * 20), y: -100 + CGFloat(i % 5 * 80))
                            .offset(y: scrollOffset/5)
                    }
                    
                    // Clouds in rainy weather
                    ForEach(0..<3) { i in
                        CloudShape()
                            .fill(Color.white.opacity(0.2 + Double(i % 3) * 0.05))
                            .frame(width: 140 + CGFloat(i * 25), height: 70 + CGFloat(i * 10))
                            .offset(x: -130 + CGFloat(i * 110), y: -160 + CGFloat(i * 30))
                            .offset(y: scrollOffset > 0 ? scrollOffset/10 : 0)
                    }
                }
            )
            
        case .stormy:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)] :
                            [Color(red: 0.25, green: 0.25, blue: 0.35), Color(red: 0.15, green: 0.15, blue: 0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Lightning effect
                    ForEach(0..<2) { i in
                        LightningShape()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(width: 15, height: 50)
                            .offset(x: -70 + CGFloat(i * 140), y: -60)
                            .blur(radius: 2)
                    }
                    
                    // Storm clouds
                    ForEach(0..<4) { i in
                        CloudShape()
                            .fill(Color.gray.opacity(0.3 + Double(i % 3) * 0.1))
                            .frame(width: 150 + CGFloat(i * 20), height: 80)
                            .offset(x: -160 + CGFloat(i * 100), y: -140 + CGFloat(i * 25))
                            .offset(y: scrollOffset > 0 ? scrollOffset/12 : 0)
                    }
                }
            )
            
        case .snowy:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                            [Color(red: 0.8, green: 0.85, blue: 0.9), Color(red: 0.6, green: 0.7, blue: 0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Snowflakes
                    ForEach(0..<30) { i in
                        Image(systemName: "snowflake")
                            .font(.system(size: CGFloat.random(in: 6...14)))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(x: -170 + CGFloat(i * 15), y: -200 + CGFloat(i % 10 * 50))
                            .offset(y: scrollOffset/4)
                    }
                    
                    // Snow clouds
                    ForEach(0..<3) { i in
                        CloudShape()
                            .fill(Color.white.opacity(0.3 + Double(i % 3) * 0.1))
                            .frame(width: 130 + CGFloat(i * 25), height: 65 + CGFloat(i * 10))
                            .offset(x: -150 + CGFloat(i * 120), y: -170 + CGFloat(i * 35))
                            .offset(y: scrollOffset > 0 ? scrollOffset/10 : 0)
                    }
                }
            )
            
        case .foggy:
            return AnyView(
                ZStack {
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.15)] :
                            [Color(red: 0.7, green: 0.7, blue: 0.75), Color(red: 0.5, green: 0.5, blue: 0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Fog layers
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 40)
                            .offset(y: -100 + CGFloat(i * 50))
                            .blur(radius: 20)
                            .offset(y: scrollOffset/8)
                    }
                }
            )
        }
    }
    
    // Stylish city header with weather info and controls
    private var cityHeader: some View {
        VStack(spacing: 0) {
            // Status bar background - frosted glass effect
            Color.clear.frame(height: safeAreaTop)
                .background(Color.white.opacity(0.2).blur(radius: 3))
            
            // Main header with blur background
            ZStack {
                // Frosted blur background
                Blur(style: .systemUltraThinMaterial)
                    .opacity(min(1.0, max(0.6, abs(scrollOffset) / 100)))
                
                HStack(spacing: 12) {
                    // City name and temperature stack
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(viewModel.selectedCity?.name ?? "Current Location")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            if let country = viewModel.selectedCity?.country, !country.isEmpty {
                                Text(country)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                        
                        if let current = viewModel.currentWeather {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("\(Int(current.temp))°")
                                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                                    .foregroundColor(themeManager.accentColor)
                                
                                if let condition = current.weather.first {
                                    Text(condition.description.capitalized)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Weather icon with animation
                    if let current = viewModel.currentWeather, let condition = current.weather.first {
                        Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                            .renderingMode(.original)
                            .font(.system(size: 40, weight: .bold))
                            .symbolRenderingMode(.multicolor)
                            .scaleEffect(iconScale)
                            .shadow(color: .black.opacity(0.1), radius: 1)
                            .animation(.interpolatingSpring(stiffness: 150, damping: 15), value: iconScale)
                    }
                    
                    // Action buttons in vertical stack
                    VStack(spacing: 10) {
                        Button {
                            showingSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color(UIColor.systemBackground).opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                                )
                        }
                        
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color(UIColor.systemBackground).opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                                )
                        }
                    }
                    .padding(.trailing, 5)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .frame(height: headerHeight - safeAreaTop)
        }
        .shadow(color: Color.black.opacity(scrollOffset < -10 ? 0.15 : 0), radius: 8)
    }
    
    // Current weather summary with visually enhanced stats
    private func currentWeatherSummary(current: CurrentWeather, condition: WeatherCondition) -> some View {
        VStack(spacing: 20) {
            // "Feels like" temperature with visual indicator
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [themeManager.accentColor.opacity(0.8), themeManager.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                        .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10)
                    
                    VStack(spacing: 0) {
                        Text("FEELS LIKE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(Int(current.feelsLike))°")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Key weather metrics
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 0) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                        
                        if !viewModel.dailyForecast.isEmpty, let today = viewModel.dailyForecast.first {
                            Text(" \(Int(today.temp.max))°")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        
                        Spacer().frame(width: 15)
                        
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                        
                        if !viewModel.dailyForecast.isEmpty, let today = viewModel.dailyForecast.first {
                            Text(" \(Int(today.temp.min))°")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "wind")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(Int(current.windSpeed)) m/s")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    
                    HStack {
                        Image(systemName: "humidity.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                        Text("\(current.humidity)%")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    
                    HStack {
                        Image(systemName: "umbrella.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        
                        if !viewModel.dailyForecast.isEmpty, let today = viewModel.dailyForecast.first {
                            Text("\(Int(today.pop * 100))%")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }
                }
                .padding(.leading, 5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.systemBackground).opacity(0.8))
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
            )
            .padding(.horizontal)
            
            // Weather highlights with modern cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                weatherCard(icon: "wind", iconColor: .blue, title: "Wind", value: "\(Int(current.windSpeed)) m/s", detail: getWindDescription(current.windSpeed))
                
                weatherCard(icon: "humidity.fill", iconColor: .cyan, title: "Humidity", value: "\(current.humidity)%", detail: getHumidityDescription(current.humidity))
                
                weatherCard(icon: "gauge", iconColor: .orange, title: "Pressure", value: "\(current.pressure) hPa", detail: getPressureDescription(current.pressure))
                
                weatherCard(icon: "sun.max.fill", iconColor: .yellow, title: "UV Index", value: "\(Int(current.uvi))", detail: getUVIndexDescription(current.uvi))
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }
    
    // Modern weather stat card design
    private func weatherCard(icon: String, iconColor: Color, title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 15)
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(UIColor.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8)
        )
    }
    
    // Modern tab selector with animated selection
    private var tabSelectorView: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 15, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(selectedTab == index ? themeManager.accentColor : Color.clear)
                                .shadow(color: selectedTab == index ? themeManager.accentColor.opacity(0.3) : Color.clear, radius: 5)
                        )
                        .foregroundColor(selectedTab == index ? .white : .primary)
                }
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.7))
                .padding(.horizontal, 8)
        )
    }
    
    // Tab content area with paging
    private func tabContentView(current: CurrentWeather) -> some View {
        TabView(selection: $selectedTab) {
            // Today tab - hourly forecast and summary
            todayTabView
                .tag(0)
            
            // Hourly tab - detailed hourly breakdown
            hourlyTabView
                .tag(1)
            
            // Weekly tab - 7-day forecast
            weeklyTabView
                .tag(2)
            
            // Details tab - comprehensive weather metrics
            detailsTabView(current: current)
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(minHeight: 650)
    }
    
    // Today tab with enhanced hourly forecast
    private var todayTabView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Next hours forecast
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Next 24 Hours")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Text("Hourly")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                            .onTapGesture {
                                withAnimation {
                                    selectedTab = 1
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.hourlyForecast.prefix(24)) { hour in
                                if let condition = hour.weather.first {
                                    hourCard(hour: hour, iconName: viewModel.getWeatherIcon(from: condition.icon))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
                )
                .padding(.horizontal)
                
                // Today's summary
                if !viewModel.dailyForecast.isEmpty, let today = viewModel.dailyForecast.first {
                    todaySummary(daily: today)
                }
                
                // Additional data visualization
                if !viewModel.hourlyForecast.isEmpty {
                    temperatureGraph
                }
                
                // Data source info
                sourceInfoView
            }
            .padding(.top, 5)
            .padding(.bottom, 30)
        }
    }
    
    // Modern hourly forecast card
    private func hourCard(hour: HourlyForecast, iconName: String) -> some View {
        VStack(spacing: 10) {
            // Time display
            Text(isCurrentHour(hour.date) ? "Now" : formatHour(hour.date))
                .font(.system(size: 14, weight: isCurrentHour(hour.date) ? .bold : .medium, design: .rounded))
                .foregroundColor(isCurrentHour(hour.date) ? themeManager.accentColor : .primary)
            
            // Icon with background for current hour
            Image(systemName: iconName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 20))
                .frame(height: 28)
                .padding(8)
                .background(
                    Circle()
                        .fill(isCurrentHour(hour.date) ? themeManager.accentColor.opacity(0.15) : Color.clear)
                )
            
            // Temperature with pop chance if applicable
            VStack(spacing: 2) {
                Text("\(Int(hour.temp))°")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentHour(hour.date) ? themeManager.accentColor : .primary)
                
                if hour.pop > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                        
                        Text("\(Int(hour.pop * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .frame(width: 85)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground).opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isCurrentHour(hour.date) ? themeManager.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
    }
    
    // Today's summary card with enhanced visuals
        private func todaySummary(daily: DailyForecast) -> some View {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Today's Summary")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    if let condition = daily.weather.first {
                        Text(condition.description.capitalized)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                // Temperature and sun times
                HStack(spacing: 20) {
                    // Temperature range circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat((daily.temp.max - daily.temp.min) / 50)) // Normalized range
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, themeManager.accentColor, .orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(Int(daily.temp.min))°")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("to")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                            
                            Text("\(Int(daily.temp.max))°")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Precipitation chance
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Precipitation")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(daily.pop * 100))% chance")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        
                        // Sunrise info
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "sunrise.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunrise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(formatTime(daily.sunrise))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        
                        // Sunset info
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "sunset.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunset")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(formatTime(daily.sunset))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
            )
            .padding(.horizontal)
        }
        
        // Temperature graph visualization
        private var temperatureGraph: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Temperature Trend")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                
                // Simplified temperature graph visualization
                ZStack {
                    // Background horizontal lines
                    VStack(spacing: 30) {
                        ForEach(0..<4) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                    
                    // Temperature line
                    GeometryReader { geo in
                        Path { path in
                            let hourlyData = Array(viewModel.hourlyForecast.prefix(12))
                            let maxTemp = hourlyData.map { $0.temp }.max() ?? 0
                            let minTemp = hourlyData.map { $0.temp }.min() ?? 0
                            let range = max(1, maxTemp - minTemp + 5) // Prevent division by zero
                            
                            let width = geo.size.width / CGFloat(hourlyData.count - 1)
                            let height = geo.size.height
                            
                            // Start point
                            let startPoint = CGPoint(
                                x: 0,
                                y: height - (CGFloat(hourlyData[0].temp - minTemp) / CGFloat(range)) * height
                            )
                            path.move(to: startPoint)
                            
                            // Connect all points
                            for i in 1..<hourlyData.count {
                                let point = CGPoint(
                                    x: CGFloat(i) * width,
                                    y: height - (CGFloat(hourlyData[i].temp - minTemp) / CGFloat(range)) * height
                                )
                                path.addLine(to: point)
                            }
                        }
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, themeManager.accentColor, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        // Temperature points
                        ForEach(0..<min(12, viewModel.hourlyForecast.count), id: \.self) { index in
                            let hourly = viewModel.hourlyForecast[index]
                            let maxTemp = viewModel.hourlyForecast.prefix(12).map { $0.temp }.max() ?? 0
                            let minTemp = viewModel.hourlyForecast.prefix(12).map { $0.temp }.min() ?? 0
                            let range = max(1, maxTemp - minTemp + 5)
                            
                            let width = geo.size.width / CGFloat(min(12, viewModel.hourlyForecast.count) - 1)
                            let height = geo.size.height
                            
                            let xPos = CGFloat(index) * width
                            let yPos = height - (CGFloat(hourly.temp - minTemp) / CGFloat(range)) * height
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                
                                Circle()
                                    .fill(isCurrentHour(hourly.date) ? themeManager.accentColor : Color.orange)
                                    .frame(width: 6, height: 6)
                            }
                            .position(x: xPos, y: yPos)
                            
                            Text("\(Int(hourly.temp))°")
                                .font(.system(size: 10, weight: isCurrentHour(hourly.date) ? .bold : .medium))
                                .foregroundColor(isCurrentHour(hourly.date) ? themeManager.accentColor : .primary)
                                .position(x: xPos, y: yPos - 15)
                            
                            if index % 2 == 0 {
                                Text(formatHour(hourly.date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .position(x: xPos, y: height + 15)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 25)
                }
                .frame(height: 130)
                .padding(.horizontal, 10)
                .padding(.top, 10)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
            )
            .padding(.horizontal)
        }
        
        // Weather data source info
        private var sourceInfoView: some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    if let lastUpdated = viewModel.lastUpdated {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("Updated \(timeAgoString(from: lastUpdated))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "cloud")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("Data: OpenWeatherMap")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    refreshWeatherData()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor.opacity(0.2))
                    )
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal, 20)
        }
        
        // Hourly tab with enhanced UI
        private var hourlyTabView: some View {
            ScrollView {
                VStack(spacing: 25) {
                    // Grouped hourly forecasts by day
                    enhancedHourlyForecast
                }
                .padding(.top, 5)
                .padding(.bottom, 30)
            }
        }
        
        // Enhanced hourly forecast view grouped by day
        private var enhancedHourlyForecast: some View {
            let groupedByDay = Dictionary(grouping: viewModel.hourlyForecast) { hourly -> String in
                let date = hourly.date
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                return formatter.string(from: date)
            }
            
            return VStack(spacing: 20) {
                ForEach(groupedByDay.keys.sorted(), id: \.self) { day in
                    if let hoursForDay = groupedByDay[day] {
                        VStack(alignment: .leading, spacing: 15) {
                            // Day header
                            Text(day)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding(.horizontal, 20)
                            
                            // Hours for this day
                            VStack(spacing: 12) {
                                ForEach(hoursForDay) { hour in
                                    if let condition = hour.weather.first {
                                        enhancedHourRow(hour: hour, condition: condition)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        
        // Enhanced hour row with more data
        private func enhancedHourRow(hour: HourlyForecast, condition: WeatherCondition) -> some View {
            HStack {
                // Time
                VStack(alignment: .center, spacing: 2) {
                    Text(isCurrentHour(hour.date) ? "Now" : formatHourWithMinutes(hour.date))
                        .font(.system(size: 15, weight: isCurrentHour(hour.date) ? .bold : .medium, design: .rounded))
                        .foregroundColor(isCurrentHour(hour.date) ? themeManager.accentColor : .primary)
                    
                    if !isCurrentHour(hour.date) {
                        Text(formatAmPm(hour.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 50)
                
                // Weather icon
                Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 18))
                    .frame(width: 30, height: 30)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(isCurrentHour(hour.date) ?
                                themeManager.accentColor.opacity(0.15) :
                                Color(UIColor.systemBackground).opacity(0.5))
                    )
                
                // Weather description
                VStack(alignment: .leading, spacing: 2) {
                    Text(condition.description.capitalized)
                        .font(.system(size: 15, weight: isCurrentHour(hour.date) ? .semibold : .regular))
                        .foregroundColor(isCurrentHour(hour.date) ? .primary : .secondary)
                    
                    // Additional weather metrics
                    HStack(spacing: 10) {
                        if hour.pop > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                                
                                Text("\(Int(hour.pop * 100))%")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "wind")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(hour.windSpeed)) m/s")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Temperature
                Text("\(Int(hour.temp))°")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentHour(hour.date) ? themeManager.accentColor : .primary)
                    .frame(width: 45, alignment: .trailing)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.systemBackground).opacity(0.8))
                    .shadow(color: Color.black.opacity(0.03), radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isCurrentHour(hour.date) ? themeManager.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        
        // Weekly tab with beautifully styled forecast
        private var weeklyTabView: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("7-Day Forecast")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 15) {
                        ForEach(viewModel.dailyForecast) { day in
                            if let condition = day.weather.first {
                                enhancedDayForecastRow(day: day, condition: condition)
                            }
                        }
                    }
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
                    )
                    .padding(.horizontal)
                    
                    // Additional weekly info
                    weeklyStatsSummary
                }
                .padding(.top, 5)
                .padding(.bottom, 30)
            }
        }
        
        // Enhanced day forecast row
        private func enhancedDayForecastRow(day: DailyForecast, condition: WeatherCondition) -> some View {
            VStack(spacing: 10) {
                HStack {
                    // Day and date
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDayName(day.date))
                            .font(.system(size: 16, weight: isToday(day.date) ? .bold : .semibold, design: .rounded))
                            .foregroundColor(isToday(day.date) ? themeManager.accentColor : .primary)
                        
                        Text(formatDateOnly(day.date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 90, alignment: .leading)
                    
                    // Weather icon and condition
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24)
                        
                        Text(condition.description.capitalized)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 120, alignment: .leading)
                    
                    Spacer()
                    
                    // Weather condition icon instead of precipitation
                    if let condition = day.weather.first {
                        HStack(spacing: 2) {
                            Image(systemName: "cloud")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            
                            Text(condition.main)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70, alignment: .trailing)
                    } else {
                        Spacer().frame(width: 70)
                    }
                }
                
                // Temperature range with beautiful visualization
                HStack(spacing: 15) {
                    // Min temp
                    Text("\(Int(day.temp.min))°")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 35, alignment: .trailing)
                    
                    // Temperature range bar
                    ZStack(alignment: .leading) {
                        // Find global min and max for proper scaling
                        let allTemps = viewModel.dailyForecast.flatMap { [$0.temp.min, $0.temp.max] }
                        let globalMin = (allTemps.min() ?? day.temp.min) - 2
                        let globalMax = (allTemps.max() ?? day.temp.max) + 2
                        let range = globalMax - globalMin
                        
                        // Calculate normalized positions
                        let normalizedMin = range > 0 ? (day.temp.min - globalMin) / range : 0
                        let normalizedMax = range > 0 ? (day.temp.max - globalMin) / range : 1
                        
                        // Background bar
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Colored temperature range
                        Capsule()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, themeManager.accentColor, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, 160 * (normalizedMax - normalizedMin)), height: 8)
                            .offset(x: 160 * normalizedMin)
                    }
                    .frame(width: 160)
                    
                    // Max temp
                    Text("\(Int(day.temp.max))°")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)
                        .frame(width: 35, alignment: .leading)
                }
                
                if isToday(day.date) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.vertical, 5)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isToday(day.date) ? Color(UIColor.systemBackground).opacity(0.9) : Color.clear)
                    .shadow(color: isToday(day.date) ? Color.black.opacity(0.05) : Color.clear, radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isToday(day.date) ? themeManager.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 15)
        }
        
        // Weekly stats summary
        private var weeklyStatsSummary: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Weekly Overview")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                
                HStack(spacing: 15) {
                    // Average temperature
                    VStack(spacing: 10) {
                        Text("Avg Temp")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(getAverageTemperature())°")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground).opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                    )
                    
                    // Rainy days count
                    VStack(spacing: 10) {
                        Text("Rainy Days")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "umbrella.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("\(getRainyDaysCount())")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground).opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                    )
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 15) {
                    // Highest temperature
                    VStack(spacing: 10) {
                        Text("Highest")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "thermometer.sun.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            
                            Text("\(getHighestTemperature())°")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground).opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                    )
                    
                    // Lowest temperature
                    VStack(spacing: 10) {
                        Text("Lowest")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "thermometer.snowflake")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("\(getLowestTemperature())°")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground).opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
            )
            .padding(.horizontal)
        }
        
        // Details tab with beautiful metrics display
        private func detailsTabView(current: CurrentWeather) -> some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced metrics cards
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Current Conditions")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 20)
                        
                        // UV Index card
                        detailCard(
                            iconName: "sun.max.fill",
                            iconColor: .yellow,
                            title: "UV Index",
                            value: "\(Int(current.uvi))",
                            description: getUVIndexDescription(current.uvi),
                            progressValue: min(current.uvi / 12.0, 1.0),
                            progressColors: [.green, .yellow, .orange, .red]
                        )
                        
                        // Wind card
                        detailCard(
                            iconName: "wind",
                            iconColor: .blue,
                            title: "Wind",
                            value: "\(Int(current.windSpeed)) m/s",
                            description: getWindDescription(current.windSpeed),
                            progressValue: min(current.windSpeed / 30.0, 1.0),
                            progressColors: [.blue, .cyan, .green, .yellow]
                        )
                        
                        // Humidity card
                        detailCard(
                            iconName: "humidity.fill",
                            iconColor: .cyan,
                            title: "Humidity",
                            value: "\(current.humidity)%",
                            description: getHumidityDescription(current.humidity),
                            progressValue: Double(current.humidity) / 100.0,
                            progressColors: [.blue, .cyan]
                        )
                        
                        // Pressure card
                        detailCard(
                            iconName: "gauge",
                            iconColor: .orange,
                            title: "Pressure",
                            value: "\(current.pressure) hPa",
                            description: getPressureDescription(current.pressure),
                            progressValue: getPressureGaugeValue(current.pressure),
                            progressColors: [.green, .yellow, .orange]
                        )
                        
                        // Visibility card
                        detailCard(
                            iconName: "eye.fill",
                            iconColor: .purple,
                            title: "Visibility",
                            value: formatVisibility(current.visibility),
                            description: getVisibilityDescription(current.visibility),
                            progressValue: min(Double(current.visibility) / 10000.0, 1.0),
                            progressColors: [.purple.opacity(0.7), .purple]
                        )
                    }
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
                    )
                    .padding(.horizontal)
                    
                    // Location information
                    enhancedLocationInfo
                }
                .padding(.top, 5)
                .padding(.bottom, 30)
            }
        }
        
    // Beautiful metric detail card
        private func detailCard(
            iconName: String,
            iconColor: Color,
            title: String,
            value: String,
            description: String,
            progressValue: Double,
            progressColors: [Color]
        ) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 16))
                            .foregroundColor(iconColor)
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                
                HStack(alignment: .lastTextBaseline) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Progress indicator
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Colored progress
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: progressColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(5, CGFloat(progressValue) * UIScreen.main.bounds.width * 0.75), height: 8)
                }
                .padding(.top, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground).opacity(0.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
            )
            .padding(.horizontal, 20)
        }
        
        // Enhanced location information
        private var enhancedLocationInfo: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Location Information")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                
                VStack(spacing: 18) {
                    // Location
                    if let city = viewModel.selectedCity {
                        infoRow(
                            icon: "mappin.circle.fill",
                            iconColor: .red,
                            title: "Location",
                            value: "\(city.name), \(city.country)"
                        )
                    }
                    
                    // Timezone
                    if let timezone = viewModel.timezone {
                        infoRow(
                            icon: "globe",
                            iconColor: .indigo,
                            title: "Timezone",
                            value: formatTimezone(timezone)
                        )
                    }
                    
                    // Last update time
                    if let lastUpdated = viewModel.lastUpdated {
                        infoRow(
                            icon: "clock.fill",
                            iconColor: .green,
                            title: "Last Updated",
                            value: timeAgoString(from: lastUpdated)
                        )
                    }
                    
                    // Data source
                    infoRow(
                        icon: "cloud.fill",
                        iconColor: .blue,
                        title: "Data Source",
                        value: "OpenWeatherMap API"
                    )
                    
                    // Refresh button
                    Button(action: {
                        refreshWeatherData()
                    }) {
                        Text("Refresh Weather Data")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemBackground).opacity(0.8))
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                )
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.6))
            )
            .padding(.horizontal)
        }
        
        // Beautiful info row
        private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        
        // MARK: - Utility Functions
        
        // Gets the current safe area insets top value safely
        private var safeAreaTop: CGFloat {
            if #available(iOS 15.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    return 0
                }
                return window.safeAreaInsets.top
            } else {
                // Fallback for iOS 14 and earlier
                let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                return keyWindow?.safeAreaInsets.top ?? 0
            }
        }
        
        // Is this hour the current hour?
        private func isCurrentHour(_ date: Date) -> Bool {
            let calendar = Calendar.current
            return calendar.isDate(date, equalTo: Date(), toGranularity: .hour)
        }
        
        // Wind speed utility for HourlyForecast
        private func getWindSpeed(_ hour: HourlyForecast) -> Double? {
            // Since HourlyForecast doesn't have windSpeed property,
            // we can compute a simulated value based on other properties
            // or return a fixed estimate for the UI
            return 5.0 // Default placeholder value
        }
        
        // Is this day today?
        private func isToday(_ date: Date) -> Bool {
            let calendar = Calendar.current
            return calendar.isDate(date, equalTo: Date(), toGranularity: .day)
        }
        
        // Format hour in 12-hour format
        private func formatHour(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            return formatter.string(from: date).lowercased()
        }
        
        // Format hour with minutes
        private func formatHourWithMinutes(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm"
            return formatter.string(from: date)
        }
        
        // Format AM/PM
        private func formatAmPm(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "a"
            return formatter.string(from: date).lowercased()
        }
        
        // Format time
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        // Format day name
        private func formatDayName(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // Format date only
        private func formatDateOnly(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        
        // Format timezone
        private func formatTimezone(_ timezone: String) -> String {
            return timezone.replacingOccurrences(of: "_", with: " ")
        }
        
        // Format time ago string
        private func timeAgoString(from date: Date) -> String {
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
            
            if let day = components.day, day > 0 {
                return day == 1 ? "\(day) day ago" : "\(day) days ago"
            }
            if let hour = components.hour, hour > 0 {
                return hour == 1 ? "\(hour) hour ago" : "\(hour) hours ago"
            }
            if let minute = components.minute, minute > 0 {
                return minute == 1 ? "\(minute) minute ago" : "\(minute) minutes ago"
            }
            return "Just now"
        }
        
        // Get average temperature for the week
        private func getAverageTemperature() -> Int {
            let dailyTemps = viewModel.dailyForecast.map { ($0.temp.min + $0.temp.max) / 2 }
            let sum = dailyTemps.reduce(0, +)
            return Int(sum / Double(max(1, dailyTemps.count)))
        }
        
        // Get rainy days count
        private func getRainyDaysCount() -> Int {
            return viewModel.dailyForecast.filter { $0.pop >= 0.3 }.count
        }
        
        // Get highest temperature in forecast
        private func getHighestTemperature() -> Int {
            let maxTemps = viewModel.dailyForecast.map { $0.temp.max }
            return Int(maxTemps.max() ?? 0)
        }
        
        // Get lowest temperature in forecast
        private func getLowestTemperature() -> Int {
            let minTemps = viewModel.dailyForecast.map { $0.temp.min }
            return Int(minTemps.min() ?? 0)
        }
        
        // Refresh the weather data
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
        
        // Get UV index description based on value
        private func getUVIndexDescription(_ uvi: Double) -> String {
            switch uvi {
            case 0..<3: return "Low"
            case 3..<6: return "Moderate"
            case 6..<8: return "High"
            case 8..<11: return "Very High"
            default: return "Extreme"
            }
        }
        
        // Get wind description based on speed
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
        
        // Get humidity description based on percentage
        private func getHumidityDescription(_ humidity: Int) -> String {
            switch humidity {
            case 0..<30: return "Low (Dry)"
            case 30..<60: return "Moderate"
            case 60..<80: return "High"
            default: return "Very High"
            }
        }
        
        // Get pressure description based on value
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
        
        // Get pressure gauge value (0.0-1.0) for visualization
        private func getPressureGaugeValue(_ pressure: Int) -> Double {
            // Map pressure to a 0.0-1.0 scale for gauge
            let minPressure: Double = 970
            let maxPressure: Double = 1040
            return min(max(Double(pressure) - minPressure, 0) / (maxPressure - minPressure), 1)
        }
        
        // Get visibility description based on meters
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
        
        // Format visibility in km
        private func formatVisibility(_ visibility: Int) -> String {
            let kilometers = Double(visibility) / 1000.0
            return String(format: "%.1f km", kilometers)
        }
    }

    // MARK: - Custom Shape Definitions

    // Custom cloud shape
    struct CloudShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.width
            let height = rect.height
            
            // Basic cloud shape with multiple circles
            path.addArc(center: CGPoint(x: width * 0.3, y: height * 0.5),
                       radius: height * 0.5,
                       startAngle: .degrees(0),
                       endAngle: .degrees(360),
                       clockwise: false)
            
            path.addArc(center: CGPoint(x: width * 0.6, y: height * 0.4),
                       radius: height * 0.6,
                       startAngle: .degrees(0),
                       endAngle: .degrees(360),
                       clockwise: false)
            
            path.addArc(center: CGPoint(x: width * 0.75, y: height * 0.5),
                       radius: height * 0.4,
                       startAngle: .degrees(0),
                       endAngle: .degrees(360),
                       clockwise: false)
            
            return path
        }
    }


    // Lightning shape
    struct LightningShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = rect.width
            let height = rect.height
            
            // Zigzag lightning bolt
            path.move(to: CGPoint(x: width * 0.5, y: 0))
            path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.4))
            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
            path.addLine(to: CGPoint(x: width * 0.1, y: height))
            
            return path
        }
    }

    // Blur effect view
    struct Blur: UIViewRepresentable {
        var style: UIBlurEffect.Style
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            UIVisualEffectView(effect: UIBlurEffect(style: style))
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: style)
        }
    }

    // Preference key to track scroll offset
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
