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
