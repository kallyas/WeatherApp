import SwiftUI

struct WeatherDetailsView: View {
    let current: CurrentWeather
    let isDarkMode: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weather Details")
                .font(.headline)
                .padding(.leading, 8)
            
            VStack(spacing: 20) {
                // First row
                HStack(spacing: 20) {
                    DetailCardView(
                        icon: "sun.max.fill",
                        title: "UV Index",
                        value: getUVIndexDescription(current.uvi),
                        colorGradient: getUVIndexGradient(current.uvi),
                        iconColor: .yellow
                    )
                    
                    DetailCardView(
                        icon: "eye.fill",
                        title: "Visibility",
                        value: formatVisibility(current.visibility),
                        colorGradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)]),
                        iconColor: .blue
                    )
                }
                
                // Second row
                HStack(spacing: 20) {
                    DetailCardView(
                        icon: "wind",
                        title: "Wind Speed",
                        value: "\(Int(current.windSpeed)) m/s",
                        colorGradient: Gradient(colors: [Color.green.opacity(0.7), Color.green.opacity(0.3)]),
                        iconColor: .green
                    )
                    
                    DetailCardView(
                        icon: "humidity.fill",
                        title: "Humidity",
                        value: "\(current.humidity)%",
                        colorGradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple.opacity(0.3)]),
                        iconColor: .purple
                    )
                }
                
                // Third row
                HStack(spacing: 20) {
                    DetailCardView(
                        icon: "gauge",
                        title: "Pressure",
                        value: formatPressure(current.pressure),
                        colorGradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.3)]),
                        iconColor: .orange
                    )
                    
                    DetailCardView(
                        icon: "thermometer",
                        title: "Feels Like",
                        value: "\(Int(current.feelsLike))°",
                        colorGradient: Gradient(colors: [Color.red.opacity(0.7), Color.red.opacity(0.3)]),
                        iconColor: .red
                    )
                }
            }
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private func getUVIndexDescription(_ uvi: Double) -> String {
        switch uvi {
        case 0..<3: return "Low (\(Int(uvi)))"
        case 3..<6: return "Moderate (\(Int(uvi)))"
        case 6..<8: return "High (\(Int(uvi)))"
        case 8..<11: return "Very High (\(Int(uvi)))"
        default: return "Extreme (\(Int(uvi)))"
        }
    }
    
    private func getUVIndexGradient(_ uvi: Double) -> Gradient {
        switch uvi {
        case 0..<3:
            return Gradient(colors: [Color.green.opacity(0.7), Color.green.opacity(0.3)])
        case 3..<6:
            return Gradient(colors: [Color.yellow.opacity(0.7), Color.yellow.opacity(0.3)])
        case 6..<8:
            return Gradient(colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.3)])
        case 8..<11:
            return Gradient(colors: [Color.red.opacity(0.7), Color.red.opacity(0.3)])
        default:
            return Gradient(colors: [Color.purple.opacity(0.7), Color.purple.opacity(0.3)])
        }
    }
    
    private func formatVisibility(_ visibility: Int) -> String {
        let kilometers = Double(visibility) / 1000.0
        return String(format: "%.1f km", kilometers)
    }
    
    private func formatPressure(_ pressure: Int) -> String {
        return "\(pressure) hPa"
    }
}

struct DetailCardView: View {
    let icon: String
    let title: String
    let value: String
    let colorGradient: Gradient
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding()
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: colorGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    LinearGradient(
                        gradient: colorGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .opacity(0.5)
        )
    }
}

struct EnhancedHourlyForecastView: View {
    let hourlyData: [HourlyForecast]
    let viewModel: WeatherViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Hourly Forecast")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: DetailedHourlyView(hourlyData: hourlyData, viewModel: viewModel)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(hourlyData) { hour in
                        if let condition = hour.weather.first {
                            EnhancedHourlyCell(
                                hour: hour,
                                iconName: viewModel.getWeatherIcon(from: condition.icon),
                                description: condition.description
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

struct EnhancedHourlyCell: View {
    let hour: HourlyForecast
    let iconName: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
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
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
}

struct DetailedHourlyView: View {
    let hourlyData: [HourlyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        List {
            ForEach(hourlyData) { hour in
                if let condition = hour.weather.first {
                    HStack {
                        // Time
                        Text(formatHour(hour.date))
                            .font(.system(size: 16))
                            .frame(width: 60, alignment: .leading)
                        
                        // Icon
                        Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                            .renderingMode(.original)
                            .font(.system(size: 22))
                            .frame(width: 40)
                        
                        // Description
                        Text(condition.description.capitalized)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Temperature
                        Text("\(Int(hour.temp))°")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("48-Hour Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, ha"
        return formatter.string(from: date)
    }
}
